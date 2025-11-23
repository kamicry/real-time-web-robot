@echo off
chcp 65001  > nul  & rem 设置代码页为UTF-8

REM ============================================================
REM Project Lanlan - Web Runner Launcher
REM This batch file invokes the PowerShell launcher script
REM ============================================================

setlocal enabledelayedexpansion

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"

REM Call the PowerShell script with proper execution policy
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%scripts\launch_web_runner.ps1"

REM PowerShell script handles all the output and cleanup
endlocal
exit /b 0
