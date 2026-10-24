@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& { param([string]$ScriptPath) $s = [System.IO.File]::ReadAllText($ScriptPath, [System.Text.Encoding]::UTF8); $sb = [scriptblock]::Create($s); & $sb @args } -ScriptPath '%~dp0convert_to_mp3.ps1'" %*
echo.
pause
