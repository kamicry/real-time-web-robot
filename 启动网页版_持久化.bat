@echo off
chcp 65001  > nul  & rem 设置代码页为UTF-8

REM ============================================================
REM Windows 持久化网页运行器启动脚本
REM This batch file invokes the PowerShell launcher script
REM 功能：启动后后台服务会持续运行，直到手动关闭此窗口
REM 即使浏览器标签页关闭，服务仍在运行
REM ============================================================

setlocal enabledelayedexpansion

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"

REM Call the PowerShell script with proper execution policy
REM --EnableShutdown flag is passed for persistent mode
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%scripts\launch_web_runner.ps1" -EnableShutdown

REM PowerShell script handles all the output and cleanup
endlocal
exit /b 0
