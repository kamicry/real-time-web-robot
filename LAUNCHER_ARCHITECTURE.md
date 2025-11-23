# Project Lanlan - Launcher Architecture

## Overview

This document describes the unified launcher architecture for Project Lanlan, which provides reliable process management, logging, and graceful shutdown capabilities for the web runner.

## Architecture

### Component Hierarchy

```
启动网页版.bat (Standard Mode)
启动网页版_持久化.bat (Persistent Mode)
    ↓
scripts/launch_web_runner.ps1 (PowerShell Launcher)
    ↓
    ├─ memory_server.py (Memory Server Process)
    │  └─ logs/memory_server.log
    │
    └─ main_server.py (Main Server Process)
       └─ logs/main_server.log
```

## Key Features

### 1. Unified Entry Point
- Both startup batch files now delegate to a single PowerShell script
- Centralized process management logic
- Easier to maintain and update

### 2. Process Management
- **Start-Process with PassThru**: Captures process objects with full control
- **Process ID Tracking**: Stores PID of spawned processes for precise cleanup
- **Automatic Cleanup**: try/finally block ensures cleanup in all scenarios
  - Normal window close
  - Ctrl+C interrupt
  - Process termination
  - Unexpected crashes

### 3. Output Redirection
- **Dual Logging**: Each process logs to separate file
  - `logs/memory_server.log` - Memory server output
  - `logs/main_server.log` - Main server output
- **Timestamp Tracking**: Each session logs with start timestamp
- **Debugging Support**: Full stdout/stderr captured for troubleshooting

### 4. Status Reporting
Clear, color-coded messages in the launcher window:
- ✅ Green: Successful startup
- ⚠️ Yellow: Warnings or partial failures
- ❌ Red: Critical errors
- 🔵 Cyan: Status information

### 5. Graceful Shutdown
- **Ctrl+C Support**: Immediately triggers cleanup
- **Window Close**: Closing the launcher window triggers cleanup
- **Process Monitoring**: Periodically checks process health
- **Forced Termination**: Uses `Stop-Process -Force` for robust cleanup

## Execution Flow

### Startup Sequence

```
1. Batch file executes
   └─ Sets SCRIPT_DIR to batch file location
   
2. PowerShell script launches
   ├─ Validates Python executable exists
   ├─ Creates logs/ directory
   └─ Initializes log files with timestamp
   
3. Memory Server starts
   ├─ Executed with: python.exe memory_server.py [--enable-shutdown]
   ├─ Process ID captured
   ├─ Output redirected to memory_server.log
   └─ 5-second initialization delay
   
4. Main Server starts
   ├─ Executed with: python.exe main_server.py
   ├─ Process ID captured
   ├─ Output redirected to main_server.log
   └─ 5-second initialization delay
   
5. Monitoring Loop
   ├─ Displays startup success message
   ├─ Shows URL: http://127.0.0.1:8000
   ├─ Periodically checks process health
   └─ Waits for user interrupt or process termination
```

### Shutdown Sequence

```
1. User closes launcher window OR presses Ctrl+C
   └─ Enters finally block
   
2. Cleanup processes:
   ├─ Iterate through stored process IDs
   ├─ Verify process still exists
   ├─ Call Stop-Process -Force
   ├─ Log process termination
   └─ Count terminated processes
   
3. Display summary
   ├─ Show cleanup completion message
   ├─ Report number of processes terminated
   ├─ Thank user message
   └─ 2-second delay before exit
   
4. Exit with code 0 (success)
```

## Batch File Variants

### 启动网页版.bat (Standard Mode)
- Calls PowerShell script without -EnableShutdown flag
- Recommended for standard usage
- Services may continue after browser closes (depends on API shutdown logic)

### 启动网页版_持久化.bat (Persistent Mode)
- Calls PowerShell script with -EnableShutdown flag
- Recommended for persistent server usage
- Services continue even when browser closes
- Suitable for development and testing

## Parameters

### PowerShell Script Parameters

```powershell
-PythonExe <string>
    Path to Python executable
    Default: env\python.exe (relative to script)

-ScriptDir <string>
    Directory containing server scripts
    Default: Parent directory of script

-EnableShutdown <switch>
    Pass --enable-shutdown flag to memory server
    Usage: Only used by persistent mode batch file
```

## Error Handling

### Validation
1. **Python Executable Check**
   - Verifies `env/python.exe` exists before starting servers
   - Displays clear error message if missing
   - Exits with code 1 on failure

2. **Path Resolution**
   - Converts relative paths to absolute paths
   - Handles UNC paths and special characters
   - Validates directory permissions

### Runtime Monitoring
- Periodically checks if processes are still running
- Detects unexpected process termination
- Reports warnings for dead processes
- Continues operation unless all processes die

### Process Cleanup
- Handles cases where process already terminated
- Gracefully continues cleanup for remaining processes
- Uses error suppression to avoid cascading failures
- Logs all termination attempts

## Log Files

### Location
```
project_root/
├── logs/
│   ├── memory_server.log
│   └── main_server.log
```

### Format
Each log file begins with:
```
=== Session started at YYYY-MM-DD HH:MM:SS ===
```

Followed by stdout and stderr from the respective process.

### Usage
- Check logs when debugging startup issues
- Review logs when processes terminate unexpectedly
- Use timestamps to correlate with system events
- Keep logs for post-mortem analysis

## Differences from Previous Implementation

### Before
- Separate `start` command for each service in batch files
- Process tracking via window titles
- Cleanup using `taskkill` filter by window title
- No centralized logging (outputs go to cmd windows)
- Limited error handling

### After
- Centralized PowerShell launcher
- Direct process ID tracking
- Cleanup using captured process objects
- Comprehensive logging to files
- Robust error handling and validation
- Better status reporting to user

## Usage Examples

### Standard Startup
```
Double-click 启动网页版.bat
```

### Persistent Startup
```
Double-click 启动网页版_持久化.bat
```

### From PowerShell (Manual)
```powershell
# Standard mode
powershell -ExecutionPolicy Bypass -File "scripts/launch_web_runner.ps1"

# Persistent mode with enable-shutdown
powershell -ExecutionPolicy Bypass -File "scripts/launch_web_runner.ps1" -EnableShutdown

# With custom paths
powershell -ExecutionPolicy Bypass -File "scripts/launch_web_runner.ps1" `
    -PythonExe "C:\Python312\python.exe" `
    -ScriptDir "C:\lanlan"
```

## Troubleshooting

### Issue: "Python executable not found"
**Solution**: Ensure `env/python.exe` exists in the project root

### Issue: One service starts but not the other
**Solution**: Check `logs/memory_server.log` or `logs/main_server.log` for error details

### Issue: Services don't stop when closing launcher window
**Solution**: Try pressing Ctrl+C in the PowerShell window, or check Task Manager for orphaned processes

### Issue: Can't delete log files while services running
**Solution**: This is expected - log files are open by the running processes. Stop the services first.

### Issue: Port 8000 already in use
**Solution**: Stop any other application using port 8000, or restart launcher

## Future Enhancements

- Add command-line flags for custom ports
- Support for custom Python virtual environments
- Integration with Windows Task Scheduler
- GUI wrapper for launcher control
- Automatic restart on crash
- Health check endpoints
- Process restart on zombie detection

## References

- PowerShell Start-Process documentation
- Windows Process Management
- UTF-8 encoding in batch files
- FastAPI server management
