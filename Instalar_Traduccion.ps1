[CmdletBinding()]
param(
    [string]$GamePath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$patchName = 'AnvilSpanish_P.pak'
$patchSource = Join-Path $PSScriptRoot $patchName
$expectedHash = '0F8AFE1E609FD38EFD4E76CF3DB118DAC9F3FD6982FEB6FB0D08EF691D87B387'
$expectedGameExeHash = '4772FF6C1ACCEB0A9671D70A4AE9383C03B20804061121AFD5001FBAFCCE87BB'

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
        Write-Host 'ERROR: Windows no concedio los permisos necesarios para instalar en la carpeta de Steam.' -ForegroundColor Red
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
        # Steam puede no tener esta clave; se siguen probando las rutas conocidas.
    }

    $knownRoots = @($roots)
    foreach ($root in $knownRoots) {
        $libraryFile = Join-Path $root 'steamapps\libraryfolders.vdf'
        if (-not (Test-Path -LiteralPath $libraryFile)) {
            continue
        }

        $libraryText = Get-Content -LiteralPath $libraryFile -Raw
        foreach ($match in [regex]::Matches($libraryText, '"path"\s+"([^"]+)"')) {
            $libraryRoot = $match.Groups[1].Value -replace '\\\\', '\'
            if ($libraryRoot) {
                $roots.Add($libraryRoot)
            }
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
        $gameExe = Join-Path $candidate 'Anvil\Binaries\Win64\Anvil-Win64-Shipping.exe'
        if (Test-Path -LiteralPath $gameExe) {
            return $candidate
        }
    }

    throw 'No se ha encontrado Anvil Empires. Puedes abrir PowerShell y ejecutar el instalador con -GamePath "RUTA_DEL_JUEGO".'
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

function Set-AnvilCultureSpanish {
    param([string]$ConfigPath)

    $lines = New-Object System.Collections.Generic.List[string]
    if (Test-Path -LiteralPath $ConfigPath) {
        foreach ($line in Get-Content -LiteralPath $ConfigPath) {
            [void]$lines.Add([string]$line)
        }
    }

    $result = New-Object System.Collections.Generic.List[string]
    $previousCultureLines = New-Object System.Collections.Generic.List[string]
    $insideInternationalization = $false
    $hadInternationalizationSection = $false
    $cultureInserted = $false

    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed -match '^\[.+\]$') {
            $insideInternationalization = ($trimmed -ieq '[Internationalization]')
            if ($insideInternationalization) {
                $hadInternationalizationSection = $true
            }
            [void]$result.Add($line)
            if ($insideInternationalization -and -not $cultureInserted) {
                [void]$result.Add('Culture=es')
                $cultureInserted = $true
            }
            continue
        }

        if ($insideInternationalization -and $line -match '^\s*Culture\s*=') {
            [void]$previousCultureLines.Add($line)
            continue
        }

        [void]$result.Add($line)
    }

    if (-not $hadInternationalizationSection) {
        if ($result.Count -gt 0 -and $result[$result.Count - 1] -ne '') {
            [void]$result.Add('')
        }
        [void]$result.Add('[Internationalization]')
        [void]$result.Add('Culture=es')
    }

    $text = ($result -join [Environment]::NewLine) + [Environment]::NewLine
    Write-Utf8TextAtomic -Path $ConfigPath -Text $text

    [pscustomobject]@{
        HadInternationalizationSection = $hadInternationalizationSection
        PreviousCultureLines = @($previousCultureLines)
    }
}

try {
    Write-Host '=== Traduccion al espanol de Anvil Empires ===' -ForegroundColor Cyan

    if (-not (Test-Path -LiteralPath $patchSource)) {
        throw "No se encuentra $patchName junto al instalador. Extrae todos los archivos del ZIP antes de continuar."
    }

    $actualHash = (Get-FileHash -LiteralPath $patchSource -Algorithm SHA256).Hash
    if ($actualHash -ne $expectedHash) {
        throw 'El PAK no coincide con esta version del instalador. Vuelve a descargar el paquete; el archivo puede estar incompleto o modificado.'
    }

    if (Get-Process -Name 'Anvil-Win64-Shipping' -ErrorAction SilentlyContinue) {
        throw 'Anvil Empires esta abierto. Cierra el juego y vuelve a ejecutar el instalador.'
    }

    $resolvedGamePath = Find-AnvilGamePath -RequestedPath $GamePath
    $gameExe = Join-Path $resolvedGamePath 'Anvil\Binaries\Win64\Anvil-Win64-Shipping.exe'
    $gameExeHash = (Get-FileHash -LiteralPath $gameExe -Algorithm SHA256).Hash
    if ($gameExeHash -ne $expectedGameExeHash) {
        throw 'Esta traduccion se ha probado solamente con la build 00235. El ejecutable instalado pertenece a otra version y no se modificara.'
    }

    $paksDirectory = Join-Path $resolvedGamePath 'Anvil\Content\Paks'
    if (-not (Test-Path -LiteralPath $paksDirectory)) {
        throw "No existe la carpeta de PAKs esperada: $paksDirectory"
    }

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupDirectory = Join-Path $env:LOCALAPPDATA "AnvilSpanishTranslation\Backups\$timestamp"
    New-Item -ItemType Directory -Path $backupDirectory -Force | Out-Null

    $engineConfig = Join-Path $env:LOCALAPPDATA 'Anvil\Saved\Config\Windows\Engine.ini'
    $engineConfigExisted = Test-Path -LiteralPath $engineConfig
    $engineConfigBackup = Join-Path $backupDirectory 'Engine.ini'
    if ($engineConfigExisted) {
        Copy-Item -LiteralPath $engineConfig -Destination $engineConfigBackup
    }

    $stateDirectory = Join-Path $env:LOCALAPPDATA 'AnvilSpanishTranslation'
    $statePath = Join-Path $stateDirectory 'install-state.json'
    $previousStateBackup = Join-Path $backupDirectory 'install-state.json'
    if (Test-Path -LiteralPath $statePath) {
        Copy-Item -LiteralPath $statePath -Destination $previousStateBackup
    }

    $patchDestination = Join-Path $paksDirectory $patchName
    $hadPreviousPatch = Test-Path -LiteralPath $patchDestination
    $previousPatchBackup = Join-Path $backupDirectory $patchName
    if (Test-Path -LiteralPath $patchDestination) {
        Copy-Item -LiteralPath $patchDestination -Destination $previousPatchBackup
    }

    try {
        Copy-Item -LiteralPath $patchSource -Destination $patchDestination -Force
        $installedHash = (Get-FileHash -LiteralPath $patchDestination -Algorithm SHA256).Hash
        if ($installedHash -ne $expectedHash) {
            throw 'La verificacion del PAK instalado ha fallado.'
        }

        $cultureState = Set-AnvilCultureSpanish -ConfigPath $engineConfig
        $installState = [ordered]@{
            Version = 1
            PatchHash = $expectedHash
            GamePath = $resolvedGamePath
            EngineConfigPath = $engineConfig
            EngineConfigExisted = $engineConfigExisted
            HadInternationalizationSection = $cultureState.HadInternationalizationSection
            PreviousCultureLines = @($cultureState.PreviousCultureLines)
            BackupDirectory = $backupDirectory
        }
        Write-Utf8TextAtomic -Path $statePath -Text (($installState | ConvertTo-Json -Depth 4) + [Environment]::NewLine)
    } catch {
        if ($engineConfigExisted -and (Test-Path -LiteralPath $engineConfigBackup)) {
            Copy-Item -LiteralPath $engineConfigBackup -Destination $engineConfig -Force
        } elseif ((-not $engineConfigExisted) -and (Test-Path -LiteralPath $engineConfig)) {
            Remove-Item -LiteralPath $engineConfig -Force
        }

        if (Test-Path -LiteralPath $previousStateBackup) {
            Copy-Item -LiteralPath $previousStateBackup -Destination $statePath -Force
        } elseif (Test-Path -LiteralPath $statePath) {
            Remove-Item -LiteralPath $statePath -Force
        }

        if ($hadPreviousPatch -and (Test-Path -LiteralPath $previousPatchBackup)) {
            Copy-Item -LiteralPath $previousPatchBackup -Destination $patchDestination -Force
        } elseif (Test-Path -LiteralPath $patchDestination) {
            Remove-Item -LiteralPath $patchDestination -Force
        }
        throw
    }

    Write-Host ''
    Write-Host 'Instalacion completada correctamente.' -ForegroundColor Green
    Write-Host "Juego: $resolvedGamePath"
    Write-Host "Parche: $patchDestination"
    Write-Host "Copia de seguridad: $backupDirectory"
    exit 0
} catch {
    Write-Host ''
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
