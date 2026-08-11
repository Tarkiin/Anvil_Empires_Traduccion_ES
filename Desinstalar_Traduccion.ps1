[CmdletBinding()]
param(
    [string]$GamePath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

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
        Remove-Item -LiteralPath $patchPath -Force
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
