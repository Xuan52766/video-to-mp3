@echo off
chcp 65001 >nul
cd /d "%~dp0"
title 影片一鍵轉 MP3 (自動匹配原音訊位元速率)

:: 呼叫 PowerShell 核心處理腳本
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0convert_to_mp3.ps1" %*

echo.
echo ==========================================================
echo 按任意鍵退出...
pause >nul
