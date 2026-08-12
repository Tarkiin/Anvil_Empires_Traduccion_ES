[CmdletBinding()]
param(
    [string]$GamePath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$expectedHash = '6E3B6639F3BD14681B0DF8F22D48344E6850B84C9E93FC6ACF625DCAF11EF4E6'

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdministrator)) {
    $arguments = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', ('"{0}"' -f $PSCommandPath)
    )
    if ($GamePath) {
        $arguments += @('-GamePath', ('"{0}"' -f $GamePath))
    }

    try {
        $elevated = Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $arguments -Wait -PassThru
        exit $elevated.ExitCode
    } catch {
        Write-Host 'ERROR: Windows no concedio los permisos necesarios para modificar la carpeta de Steam.' -ForegroundColor Red
        exit 1
    }
}

function Get-SteamRoots {
    $roots = New-Object System.Collections.Generic.List[string]
    if (${env:ProgramFiles(x86)}) {
        $roots.Add((Join-Path ${env:ProgramFiles(x86)} 'Steam'))
    }
    try {
        $steamRegistry = (Get-ItemProperty -LiteralPath 'HKCU:\Software\Valve\Steam' -ErrorAction Stop).SteamPath
        if ($steamRegistry) {
            $roots.Add(($steamRegistry -replace '/', '\'))
        }
    } catch {
    }

    foreach ($root in @($roots)) {
        $libraryFile = Join-Path $root 'steamapps\libraryfolders.vdf'
        if (-not (Test-Path -LiteralPath $libraryFile)) {
            continue
        }
        $libraryText = Get-Content -LiteralPath $libraryFile -Raw
        foreach ($match in [regex]::Matches($libraryText, '"path"\s+"([^"]+)"')) {
            $roots.Add(($match.Groups[1].Value -replace '\\\\', '\'))
        }
    }
    $roots | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique
}

function Find-AnvilGamePath {
    param([string]$RequestedPath)
    $candidates = New-Object System.Collections.Generic.List[string]
    if ($RequestedPath) {
        $candidates.Add([IO.Path]::GetFullPath($RequestedPath))
    }
    foreach ($steamRoot in Get-SteamRoots) {
        $candidates.Add((Join-Path $steamRoot 'steamapps\common\Anvil Playtest'))
    }
    foreach ($candidate in ($candidates | Select-Object -Unique)) {
        if (Test-Path -LiteralPath (Join-Path $candidate 'Anvil\Binaries\Win64\Anvil-Win64-Shipping.exe')) {
            return $candidate
        }
    }
    throw 'No se ha encontrado Anvil Empires. Ejecuta el desinstalador con -GamePath "RUTA_DEL_JUEGO".'
}

function Write-Utf8TextAtomic {
    param([string]$Path, [string]$Text)

    $directory = Split-Path -Parent $Path
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    $temporaryPath = Join-Path $directory ('.anvil-spanish-{0}.tmp' -f [guid]::NewGuid().ToString('N'))
    $replacementBackup = Join-Path $directory ('.anvil-spanish-{0}.replace-backup' -f [guid]::NewGuid().ToString('N'))
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    try {
        [IO.File]::WriteAllText($temporaryPath, $Text, $utf8NoBom)
        if (Test-Path -LiteralPath $Path) {
            [IO.File]::Replace($temporaryPath, $Path, $replacementBackup, $true)
        } else {
            [IO.File]::Move($temporaryPath, $Path)
        }
    } finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
        if (Test-Path -LiteralPath $replacementBackup) {
            Remove-Item -LiteralPath $replacementBackup -Force
        }
    }
}

function Restore-AnvilCulture {
    param(
        [string]$ConfigPath,
        [string[]]$PreviousCultureLines
    )

    if (-not (Test-Path -LiteralPath $ConfigPath)) {
        return
    }

    $result = New-Object System.Collections.Generic.List[string]
    $insideInternationalization = $false
    $foundInternationalization = $false
    $previousInserted = $false

    foreach ($line in Get-Content -LiteralPath $ConfigPath) {
        $trimmed = $line.Trim()
        if ($trimmed -match '^\[.+\]$') {
            $insideInternationalization = ($trimmed -ieq '[Internationalization]')
            if ($insideInternationalization) {
                $foundInternationalization = $true
            }
            [void]$result.Add([string]$line)
            if ($insideInternationalization -and -not $previousInserted) {
                foreach ($previousLine in @($PreviousCultureLines)) {
                    [void]$result.Add([string]$previousLine)
                }
                $previousInserted = $true
            }
            continue
        }

        if ($insideInternationalization -and $line -match '^\s*Culture\s*=') {
            continue
        }

        [void]$result.Add([string]$line)
    }

    if ((-not $foundInternationalization) -and @($PreviousCultureLines).Count -gt 0) {
        if ($result.Count -gt 0 -and $result[$result.Count - 1] -ne '') {
            [void]$result.Add('')
        }
        [void]$result.Add('[Internationalization]')
        foreach ($previousLine in @($PreviousCultureLines)) {
            [void]$result.Add([string]$previousLine)
        }
    }

    Write-Utf8TextAtomic -Path $ConfigPath -Text (($result -join [Environment]::NewLine) + [Environment]::NewLine)
}

try {
    Write-Host '=== Desinstalar traduccion de Anvil Empires ===' -ForegroundColor Cyan
    if (Get-Process -Name 'Anvil-Win64-Shipping' -ErrorAction SilentlyContinue) {
        throw 'Anvil Empires esta abierto. Cierra el juego y vuelve a ejecutar el desinstalador.'
    }

    $resolvedGamePath = Find-AnvilGamePath -RequestedPath $GamePath
    $patchPath = Join-Path $resolvedGamePath 'Anvil\Content\Paks\AnvilSpanish_P.pak'

    if (Test-Path -LiteralPath $patchPath) {
        $installedHash = (Get-FileHash -LiteralPath $patchPath -Algorithm SHA256).Hash
        if ($installedHash -ne $expectedHash) {
            throw 'El archivo AnvilSpanish_P.pak instalado pertenece a otra version o modificacion. No se eliminara automaticamente.'
        }

        $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $backupDirectory = Join-Path $env:LOCALAPPDATA "AnvilSpanishTranslation\Backups\uninstall-$timestamp"
        New-Item -ItemType Directory -Path $backupDirectory -Force | Out-Null
        Copy-Item -LiteralPath $patchPath -Destination (Join-Path $backupDirectory 'AnvilSpanish_P.pak')

        $statePath = Join-Path $env:LOCALAPPDATA 'AnvilSpanishTranslation\install-state.json'
        if (Test-Path -LiteralPath $statePath) {
            $installState = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
            if ($installState.PatchHash -ne $expectedHash) {
                throw 'El estado de instalacion pertenece a otra version. No se modificara Engine.ini automaticamente.'
            }

            $configPath = [string]$installState.EngineConfigPath
            if ($configPath -and (Test-Path -LiteralPath $configPath)) {
                Copy-Item -LiteralPath $configPath -Destination (Join-Path $backupDirectory 'Engine.ini')
                Restore-AnvilCulture -ConfigPath $configPath -PreviousCultureLines @($installState.PreviousCultureLines)
            }
        } else {
            Write-Host 'Aviso: no existe el estado de instalacion; Culture=es no se modificara automaticamente.' -ForegroundColor Yellow
        }

        Remove-Item -LiteralPath $patchPath -Force
        if (Test-Path -LiteralPath $statePath) {
            Remove-Item -LiteralPath $statePath -Force
        }
        Write-Host "Parche eliminado: $patchPath" -ForegroundColor Green
        Write-Host "Copia recuperable: $backupDirectory"
    } else {
        Write-Host 'La traduccion no estaba instalada; no se ha eliminado ningun archivo.' -ForegroundColor Yellow
    }

    Write-Host 'Las partidas y los archivos originales del juego no se han modificado.'
    exit 0
} catch {
    Write-Host ''
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
