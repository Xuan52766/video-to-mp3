@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0convert_to_mp3.ps1" %*
echo.
pause
