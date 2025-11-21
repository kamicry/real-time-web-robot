@echo off
chcp 65001  > nul  & rem 设置代码页为UTF-8

REM ============================================================
REM Windows 持久化网页运行器启动脚本
REM 功能：启动后后台服务会持续运行，直到手动关闭此窗口
REM 即使浏览器标签页关闭，服务仍在运行
REM ============================================================

setlocal enabledelayedexpansion

REM 获取当前目录
set "SCRIPT_DIR=%~dp0"
set "PYTHON=%SCRIPT_DIR%env\python.exe"

REM 检查Python环境是否存在
if not exist "%PYTHON%" (
    echo.
    echo 错误：找不到Python环境
    echo 期望位置: %PYTHON%
    echo.
    echo 请确保env目录存在并包含Python可执行文件
    pause
    exit /b 1
)

echo.
echo ============================================================
echo 正在启动 Project Lanlan 网页版应用程序
echo ============================================================
echo.
echo 启动内存服务器...

REM 启动Memory Server（在新窗口中启动，最小化显示）
start "Memory Server" /MIN "%PYTHON%" "%SCRIPT_DIR%memory_server.py" --enable-shutdown

REM 等待Memory Server启动完成
timeout /t 5 > nul

echo 启动主服务器...

REM 启动Main Server（在新窗口中启动，最小化显示）
start "Main Server" /MIN "%PYTHON%" "%SCRIPT_DIR%main_server.py"

REM 等待主服务器启动完成（增加等待时间确保服务完全启动）
timeout /t 5 > nul

echo.
echo ============================================================
echo 服务已启动！
echo.
echo 请手动打开浏览器访问：
echo http://127.0.0.1:8000
echo.
echo 要停止所有服务，请关闭此窗口或按 Ctrl+C
echo ============================================================
echo.

REM 保持窗口打开，监听关闭信号
REM 这样用户关闭此窗口时，所有后台进程也会被终止
title Project Lanlan - Web Runner

REM 使用PAUSE来让窗口保持打开
pause

REM 用户关闭窗口前显示清理消息
echo.
echo 正在清理资源并关闭所有服务...
echo.

REM 终止Memory Server和Main Server窗口中的进程
taskkill /F /FI "WINDOWTITLE eq Memory Server*" 2>nul
taskkill /F /FI "WINDOWTITLE eq Main Server*" 2>nul

REM 额外保险：终止所有相关的Python进程（如果上面没有终止成功）
taskkill /F /IM python.exe /FI "WINDOWTITLE eq*Server*" 2>nul

echo 清理完成。应用程序已停止。
echo.
pause

exit /b 0
