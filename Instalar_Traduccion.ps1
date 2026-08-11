[CmdletBinding()]
param(
    [string]$GamePath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$patchName = 'AnvilSpanish_P.pak'
$patchSource = Join-Path $PSScriptRoot $patchName
$expectedHash = 'EBF7B1F05F6B8F048100FA0937F17F07D23F544B591296F44B1E7515D8D71964'

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

function Set-AnvilCultureSpanish {
    param(
        [string]$ConfigPath,
        [string]$BackupDirectory
    )

    $configDirectory = Split-Path -Parent $ConfigPath
    New-Item -ItemType Directory -Path $configDirectory -Force | Out-Null

    if (Test-Path -LiteralPath $ConfigPath) {
        Copy-Item -LiteralPath $ConfigPath -Destination (Join-Path $BackupDirectory 'Engine.ini')
        $lines = New-Object System.Collections.Generic.List[string]
        foreach ($line in Get-Content -LiteralPath $ConfigPath) {
            $lines.Add([string]$line)
        }
    } else {
        $lines = New-Object System.Collections.Generic.List[string]
    }

    $sectionIndex = -1
    $sectionEnd = $lines.Count
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -ieq '[Internationalization]') {
            $sectionIndex = $i
            for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                if ($lines[$j].Trim() -match '^\[.+\]$') {
                    $sectionEnd = $j
                    break
                }
            }
            break
        }
    }

    if ($sectionIndex -lt 0) {
        if ($lines.Count -gt 0 -and $lines[$lines.Count - 1] -ne '') {
            $lines.Add('')
        }
        $lines.Add('[Internationalization]')
        $lines.Add('Culture=es')
    } else {
        $cultureIndex = -1
        for ($i = $sectionIndex + 1; $i -lt $sectionEnd; $i++) {
            if ($lines[$i] -match '^\s*Culture\s*=') {
                $cultureIndex = $i
                break
            }
        }

        if ($cultureIndex -ge 0) {
            $lines[$cultureIndex] = 'Culture=es'
        } else {
            $lines.Insert($sectionIndex + 1, 'Culture=es')
        }
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $temporaryConfig = "$ConfigPath.anvil-spanish.tmp"
    try {
        [IO.File]::WriteAllLines($temporaryConfig, $lines, $utf8NoBom)
        Move-Item -LiteralPath $temporaryConfig -Destination $ConfigPath -Force
    } finally {
        if (Test-Path -LiteralPath $temporaryConfig) {
            Remove-Item -LiteralPath $temporaryConfig -Force
        }
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
    $paksDirectory = Join-Path $resolvedGamePath 'Anvil\Content\Paks'
    if (-not (Test-Path -LiteralPath $paksDirectory)) {
        throw "No existe la carpeta de PAKs esperada: $paksDirectory"
    }

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupDirectory = Join-Path $env:LOCALAPPDATA "AnvilSpanishTranslation\Backups\$timestamp"
    New-Item -ItemType Directory -Path $backupDirectory -Force | Out-Null

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

        $engineConfig = Join-Path $env:LOCALAPPDATA 'Anvil\Saved\Config\Windows\Engine.ini'
        Set-AnvilCultureSpanish -ConfigPath $engineConfig -BackupDirectory $backupDirectory
    } catch {
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
