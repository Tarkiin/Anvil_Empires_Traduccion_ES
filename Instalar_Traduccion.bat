@echo off
setlocal
title Instalar traduccion de Anvil Empires
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Instalar_Traduccion.ps1"
set "RESULT=%ERRORLEVEL%"
echo.
if not "%RESULT%"=="0" echo La instalacion no se completo. Revisa el mensaje anterior.
pause
exit /b %RESULT%
