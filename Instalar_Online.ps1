[CmdletBinding()]
param(
    [string]$GamePath,
    [string]$Repository = 'Tarkiin/Anvil_Empires_Traduccion_ES',
    [string]$Branch = 'main',
    [string]$ApiBase = 'https://api.github.com',
    [string]$RawBase = 'https://raw.githubusercontent.com',
    [string]$StateRoot,
    [switch]$DownloadOnly
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

if (-not $StateRoot) {
    if ($env:ANVIL_TRANSLATION_STATE_ROOT) {
        $StateRoot = $env:ANVIL_TRANSLATION_STATE_ROOT
    } else {
        $StateRoot = Join-Path $env:LOCALAPPDATA 'AnvilSpanishTranslation'
    }
}

if ($env:ANVIL_TRANSLATION_DOWNLOAD_ONLY -eq '1') {
    $DownloadOnly = $true
}

$headers = @{
    'Accept' = 'application/vnd.github+json'
    'User-Agent' = 'Anvil-Empires-Spanish-Installer'
}
$downloadsRoot = Join-Path $StateRoot 'Downloads'
$lastSuccessfulPath = Join-Path $downloadsRoot 'latest-successful.txt'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
} catch {
    # TLS 1.2 ya puede ser el valor predeterminado del sistema.
}

function Write-Utf8TextAtomic {
    param([string]$Path, [string]$Text)

    $directory = Split-Path -Parent $Path
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    $temporaryPath = Join-Path $directory ('.anvil-online-{0}.tmp' -f [guid]::NewGuid().ToString('N'))
    try {
        [IO.File]::WriteAllText($temporaryPath, $Text, $utf8NoBom)
        Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
    } finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
}

function Get-CachedCommitSha {
    if (-not (Test-Path -LiteralPath $lastSuccessfulPath)) {
        return $null
    }

    $cachedSha = (Get-Content -LiteralPath $lastSuccessfulPath -Raw).Trim().ToLowerInvariant()
    if ($cachedSha -notmatch '^[0-9a-f]{40}$') {
        return $null
    }

    $cachedDirectory = Join-Path $downloadsRoot $cachedSha
    if (-not (Test-Path -LiteralPath $cachedDirectory -PathType Container)) {
        return $null
    }

    return $cachedSha
}

function Get-LatestCommitSha {
    $escapedBranch = [Uri]::EscapeDataString($Branch)
    $commitUri = '{0}/repos/{1}/commits/{2}' -f $ApiBase.TrimEnd('/'), $Repository, $escapedBranch

    try {
        Write-Host 'Consultando la ultima version publicada en GitHub...'
        $response = Invoke-RestMethod -UseBasicParsing -Uri $commitUri -Headers $headers
        $sha = ([string]$response.sha).Trim().ToLowerInvariant()
        if ($sha -notmatch '^[0-9a-f]{40}$') {
            throw 'GitHub no ha devuelto un identificador de version valido.'
        }
        return $sha
    } catch {
        $cachedSha = Get-CachedCommitSha
        if ($cachedSha) {
            Write-Warning 'No se pudo consultar GitHub. Se intentara usar la ultima version verificada guardada en este equipo.'
            return $cachedSha
        }
        throw "No se pudo consultar la ultima version en GitHub y no existe una copia verificada en cache. $($_.Exception.Message)"
    }
}

function Download-FileAtomic {
    param([string]$Uri, [string]$Destination)

    $directory = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    $temporaryPath = Join-Path $directory ('.anvil-download-{0}.tmp' -f [guid]::NewGuid().ToString('N'))
    try {
        Invoke-WebRequest -UseBasicParsing -Uri $Uri -Headers $headers -OutFile $temporaryPath
        if (-not (Test-Path -LiteralPath $temporaryPath) -or (Get-Item -LiteralPath $temporaryPath).Length -le 0) {
            throw "La descarga esta vacia: $Uri"
        }
        Move-Item -LiteralPath $temporaryPath -Destination $Destination -Force
    } finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
}

function Get-ExpectedPakHash {
    param([string]$ManifestPath)

    $manifest = Get-Content -LiteralPath $ManifestPath -Raw
    $match = [regex]::Match($manifest, '(?im)^\s*([0-9a-f]{64})\s+\*?AnvilSpanish_P\.pak\s*$')
    if (-not $match.Success) {
        throw 'SHA256SUMS.txt no contiene un hash valido para AnvilSpanish_P.pak.'
    }
    return $match.Groups[1].Value.ToUpperInvariant()
}

function Get-Sha256Hex {
    param([string]$Path)

    $stream = [IO.File]::OpenRead($Path)
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $sha256.ComputeHash($stream)
        return ([BitConverter]::ToString($hashBytes) -replace '-', '')
    } finally {
        $sha256.Dispose()
        $stream.Dispose()
    }
}

function Test-InstallerMatchesPackage {
    param([string]$InstallerPath, [string]$ExpectedHash)

    if (-not (Test-Path -LiteralPath $InstallerPath -PathType Leaf)) {
        return $false
    }

    $installerText = Get-Content -LiteralPath $InstallerPath -Raw
    $hashMatch = [regex]::Match($installerText, "\`$expectedHash\s*=\s*'([0-9A-Fa-f]{64})'")
    if (-not $hashMatch.Success -or $hashMatch.Groups[1].Value.ToUpperInvariant() -ne $ExpectedHash) {
        return $false
    }

    $tokens = $null
    $parseErrors = $null
    [Management.Automation.Language.Parser]::ParseFile($InstallerPath, [ref]$tokens, [ref]$parseErrors) | Out-Null
    return ($parseErrors.Count -eq 0)
}

function Ensure-VersionPackage {
    param([string]$CommitSha)

    $versionDirectory = Join-Path $downloadsRoot $CommitSha
    New-Item -ItemType Directory -Path $versionDirectory -Force | Out-Null

    $manifestPath = Join-Path $versionDirectory 'SHA256SUMS.txt'
    $installerPath = Join-Path $versionDirectory 'Instalar_Traduccion.ps1'
    $pakPath = Join-Path $versionDirectory 'AnvilSpanish_P.pak'
    $rawRoot = '{0}/{1}/{2}' -f $RawBase.TrimEnd('/'), $Repository, $CommitSha

    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        Write-Host 'Descargando el manifiesto de integridad...'
        Download-FileAtomic -Uri "$rawRoot/SHA256SUMS.txt" -Destination $manifestPath
    }

    try {
        $expectedHash = Get-ExpectedPakHash -ManifestPath $manifestPath
    } catch {
        Write-Host 'El manifiesto en cache no es valido; descargandolo de nuevo...'
        Download-FileAtomic -Uri "$rawRoot/SHA256SUMS.txt" -Destination $manifestPath
        $expectedHash = Get-ExpectedPakHash -ManifestPath $manifestPath
    }

    $pakIsValid = $false
    if (Test-Path -LiteralPath $pakPath -PathType Leaf) {
        $pakIsValid = ((Get-Sha256Hex -Path $pakPath) -eq $expectedHash)
    }
    if (-not $pakIsValid) {
        Write-Host 'Descargando el parche de traduccion...'
        Download-FileAtomic -Uri "$rawRoot/AnvilSpanish_P.pak" -Destination $pakPath
        $pakIsValid = ((Get-Sha256Hex -Path $pakPath) -eq $expectedHash)
    } else {
        Write-Host 'El parche de esta version ya esta verificado en cache; no es necesario descargarlo de nuevo.'
    }
    if (-not $pakIsValid) {
        throw 'El PAK descargado no coincide con el SHA-256 publicado en GitHub.'
    }

    if (-not (Test-InstallerMatchesPackage -InstallerPath $installerPath -ExpectedHash $expectedHash)) {
        Write-Host 'Descargando el instalador correspondiente al parche...'
        Download-FileAtomic -Uri "$rawRoot/Instalar_Traduccion.ps1" -Destination $installerPath
    }
    if (-not (Test-InstallerMatchesPackage -InstallerPath $installerPath -ExpectedHash $expectedHash)) {
        throw 'El instalador descargado no es valido o no corresponde al PAK publicado.'
    }

    Write-Utf8TextAtomic -Path $lastSuccessfulPath -Text ($CommitSha + [Environment]::NewLine)
    return [pscustomobject]@{
        CommitSha = $CommitSha
        Directory = $versionDirectory
        InstallerPath = $installerPath
        PakPath = $pakPath
        PakHash = $expectedHash
    }
}

try {
    Write-Host '=== Instalador online de la traduccion de Anvil Empires traducido por Tarkin ===' -ForegroundColor Cyan
    $commitSha = Get-LatestCommitSha
    $package = Ensure-VersionPackage -CommitSha $commitSha
    Write-Host ('Version preparada: {0}' -f $package.CommitSha.Substring(0, 12)) -ForegroundColor Green

    if ($DownloadOnly) {
        Write-Host "Descarga y verificacion completadas: $($package.Directory)"
        exit 0
    }

    if ($GamePath) {
        & $package.InstallerPath -GamePath $GamePath
    } else {
        & $package.InstallerPath
    }

    if ($null -ne $LASTEXITCODE) {
        exit $LASTEXITCODE
    }
    exit 0
} catch {
    Write-Host ''
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
