@echo off
chcp 65001  > nul  & rem 设置代码页为UTF-8

REM ------------ 启动两个服务（在新窗口中运行，最小化显示） ----------
echo.
echo 正在启动服务器...

REM 启动Memory Server（在新窗口中启动，最小化显示）
start "Memory Server" /MIN "%~dp0env\python.exe" "%~dp0memory_server.py" --enable-shutdown
timeout /t 5 > nul

REM 启动Main Server（在新窗口中启动，最小化显示）
start "Main Server" /MIN "%~dp0env\python.exe" "%~dp0main_server.py"

REM 等待主服务器启动完成（增加等待时间确保服务完全启动）
timeout /t 5 > nul

echo.
echo 服务已启动，窗口将保持打开状态。
echo 请手动打开浏览器访问: http://127.0.0.1:8000
echo 关闭此窗口以停止所有服务。
echo.
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
