# PowerShell Script for Persistent Web Runner
# This script starts both memory_server.py and main_server.py with proper process management
# 
# Usage: powershell -ExecutionPolicy Bypass -File "scripts/launch_web_runner.ps1"

param(
    [string]$PythonExe = "",
    [string]$ScriptDir = "",
    [switch]$EnableShutdown = $false
)

# If parameters not provided, use environment or current directory
if (-not $PythonExe) {
    $PythonExe = "$PSScriptRoot\..\env\python.exe"
}

if (-not $ScriptDir) {
    $ScriptDir = "$PSScriptRoot\.."
}

# Convert paths to absolute
$PythonExe = Resolve-Path $PythonExe -ErrorAction SilentlyContinue
$ScriptDir = Resolve-Path $ScriptDir -ErrorAction SilentlyContinue

# Validate Python executable exists
if (-not (Test-Path $PythonExe)) {
    Write-Host ""
    Write-Host "错误：找不到Python可执行文件" -ForegroundColor Red
    Write-Host "期望位置: $PythonExe" -ForegroundColor Red
    Write-Host ""
    Write-Host "请确保 env 目录存在并包含 python.exe" -ForegroundColor Red
    Write-Host ""
    Read-Host "按Enter键退出"
    exit 1
}

# Create logs directory
$LogsDir = "$ScriptDir\logs"
if (-not (Test-Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir | Out-Null
}

# Log file paths
$MemoryServerLog = "$LogsDir\memory_server.log"
$MainServerLog = "$LogsDir\main_server.log"

# Initialize log files with timestamp
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"=== Session started at $Timestamp ===" | Out-File -FilePath $MemoryServerLog -Encoding UTF8
"=== Session started at $Timestamp ===" | Out-File -FilePath $MainServerLog -Encoding UTF8

# Display startup banner
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "正在启动 Project Lanlan 网页版应用程序" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Array to store spawned process handles
$ProcessHandles = @()

try {
    # Start Memory Server
    Write-Host "启动内存服务器..." -ForegroundColor Yellow
    
    $MemoryServerCmd = "$ScriptDir\memory_server.py"
    
    try {
        # Prepare arguments
        $MemoryArgs = @($MemoryServerCmd)
        if ($EnableShutdown) {
            $MemoryArgs += "--enable-shutdown"
        }
        
        # Start process with output redirection
        $MemoryProcess = Start-Process -FilePath $PythonExe `
            -ArgumentList $MemoryArgs `
            -NoNewWindow `
            -PassThru `
            -RedirectStandardOutput $MemoryServerLog `
            -RedirectStandardError ([System.IO.Path]::Combine($LogsDir, "memory_server_error.log"))
        
        if ($MemoryProcess) {
            $ProcessHandles += $MemoryProcess
            Write-Host "内存服务器已启动 (PID: $($MemoryProcess.Id))" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "警告：无法启动内存服务器，继续启动主服务器..." -ForegroundColor Yellow
        Write-Host "错误: $_" -ForegroundColor Yellow
    }
    
    # Wait for Memory Server to initialize
    Start-Sleep -Seconds 5
    
    # Start Main Server
    Write-Host "启动主服务器..." -ForegroundColor Yellow
    
    try {
        $MainServerCmd = "$ScriptDir\main_server.py"
        
        # Start process with output redirection
        $MainProcess = Start-Process -FilePath $PythonExe `
            -ArgumentList $MainServerCmd `
            -NoNewWindow `
            -PassThru `
            -RedirectStandardOutput $MainServerLog `
            -RedirectStandardError ([System.IO.Path]::Combine($LogsDir, "main_server_error.log"))
        
        if ($MainProcess) {
            $ProcessHandles += $MainProcess
            Write-Host "主服务器已启动 (PID: $($MainProcess.Id))" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "警告：无法启动主服务器" -ForegroundColor Yellow
        Write-Host "错误: $_" -ForegroundColor Yellow
    }
    
    # Wait for Main Server to initialize
    Start-Sleep -Seconds 5
    
    # Display status information
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "服务已启动！" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "请手动打开浏览器访问：" -ForegroundColor White
    Write-Host "http://127.0.0.1:8000" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "日志文件位置：" -ForegroundColor White
    Write-Host "内存服务器: $MemoryServerLog" -ForegroundColor Gray
    Write-Host "主服务器: $MainServerLog" -ForegroundColor Gray
    Write-Host ""
    Write-Host "要停止所有服务，请关闭此窗口或按 Ctrl+C" -ForegroundColor White
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Monitor processes and wait for user input or process termination
    Write-Host "服务正在运行中..." -ForegroundColor Green
    Write-Host "按 Ctrl+C 或关闭此窗口以停止服务" -ForegroundColor Gray
    Write-Host ""
    
    # Keep the script running until interrupted
    while ($true) {
        # Check if any process has exited unexpectedly
        $ActiveProcesses = @()
        foreach ($proc in $ProcessHandles) {
            if (-not (Get-Process -Id $proc.Id -ErrorAction SilentlyContinue)) {
                Write-Host "警告：PID $($proc.Id) 的进程已退出" -ForegroundColor Yellow
            }
            else {
                $ActiveProcesses += $proc
            }
        }
        $ProcessHandles = $ActiveProcesses
        
        # If no processes are running, ask user if they want to continue
        if ($ProcessHandles.Count -eq 0) {
            Write-Host ""
            Write-Host "所有服务进程已停止。" -ForegroundColor Yellow
            break
        }
        
        Start-Sleep -Seconds 1
    }
}
catch {
    Write-Host ""
    Write-Host "错误: $_" -ForegroundColor Red
    Write-Host ""
}
finally {
    # Cleanup: Stop all spawned processes
    Write-Host ""
    Write-Host "正在清理资源并关闭所有服务..." -ForegroundColor Yellow
    
    $StoppedCount = 0
    foreach ($proc in $ProcessHandles) {
        try {
            $procObj = Get-Process -Id $proc.Id -ErrorAction SilentlyContinue
            if ($procObj) {
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                $StoppedCount++
                Write-Host "已停止进程: PID $($proc.Id) ($($procObj.ProcessName))" -ForegroundColor Gray
            }
        }
        catch {
            # Process already terminated
        }
    }
    
    Write-Host ""
    if ($StoppedCount -gt 0) {
        Write-Host "清理完成。$StoppedCount 个应用程序进程已停止。" -ForegroundColor Green
    }
    else {
        Write-Host "清理完成。应用程序已停止。" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "感谢使用 Project Lanlan！" -ForegroundColor Cyan
    Write-Host ""
    
    Start-Sleep -Seconds 2
}

exit 0
