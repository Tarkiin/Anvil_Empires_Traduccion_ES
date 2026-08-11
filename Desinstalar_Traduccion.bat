@echo off
setlocal
title Desinstalar traduccion de Anvil Empires
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Desinstalar_Traduccion.ps1"
set "RESULT=%ERRORLEVEL%"
echo.
if not "%RESULT%"=="0" echo La desinstalacion no se completo. Revisa el mensaje anterior.
pause
exit /b %RESULT%
