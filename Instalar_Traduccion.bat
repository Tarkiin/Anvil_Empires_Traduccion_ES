@echo off
setlocal
title Instalar traduccion de Anvil Empires
if not defined ANVIL_BOOTSTRAP_URL set "ANVIL_BOOTSTRAP_URL=https://raw.githubusercontent.com/Tarkiin/Anvil_Empires_Traduccion_ES/main/Instalar_Online.ps1"
set "ANVIL_LOCAL_BOOTSTRAP=%~dp0Instalar_Online.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue';" ^
  "$root=if($env:ANVIL_BOOTSTRAP_ROOT){$env:ANVIL_BOOTSTRAP_ROOT}else{Join-Path $env:LOCALAPPDATA 'AnvilSpanishTranslation\Bootstrap'}; New-Item -ItemType Directory -Path $root -Force | Out-Null;" ^
  "$target=Join-Path $root 'Instalar_Online.ps1'; $temp=Join-Path $root ('.bootstrap-'+[guid]::NewGuid().ToString('N')+'.tmp');" ^
  "try { [Net.ServicePointManager]::SecurityProtocol=[Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -UseBasicParsing -Uri $env:ANVIL_BOOTSTRAP_URL -OutFile $temp; $tokens=$null; $errors=$null; [Management.Automation.Language.Parser]::ParseFile($temp,[ref]$tokens,[ref]$errors) | Out-Null; if($errors.Count -ne 0){throw 'El instalador online descargado contiene errores de sintaxis.'}; Move-Item -LiteralPath $temp -Destination $target -Force } catch { if(-not (Test-Path -LiteralPath $target)){if(Test-Path -LiteralPath $env:ANVIL_LOCAL_BOOTSTRAP){Copy-Item -LiteralPath $env:ANVIL_LOCAL_BOOTSTRAP -Destination $target -Force}else{throw}}; Write-Warning 'No se pudo actualizar el instalador online; se usara la copia guardada.' } finally { if(Test-Path -LiteralPath $temp){Remove-Item -LiteralPath $temp -Force} };" ^
  "& $target"
set "RESULT=%ERRORLEVEL%"
echo.
if not "%RESULT%"=="0" echo La instalacion no se completo. Revisa el mensaje anterior.
if not "%ANVIL_TRANSLATION_NO_PAUSE%"=="1" pause
exit /b %RESULT%
