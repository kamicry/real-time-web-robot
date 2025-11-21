@echo off
chcp 65001  > nul  & rem 设置代码页为UTF-8

REM ------------ 启动两个服务（后台运行，保持窗口打开） ----------
echo.
echo 正在启动服务器...

REM 启动Memory Server（后台进程）
start "" /B "%~dp0env\python.exe" "%~dp0memory_server.py" --enable-shutdown
timeout /t 3 > nul

REM 启动Main Server并打开浏览器到主页面
start "" /B "%~dp0env\python.exe" "%~dp0main_server.py" --open-browser --page index

echo.
echo 服务已启动，窗口将保持打开状态。
echo 关闭此窗口以停止所有服务。
echo.
pause
