# Manual Testing Guide - Launcher Architecture

This document describes how to manually test the new unified launcher architecture to ensure all features work correctly.

## Test Environment Requirements

- Windows OS with PowerShell 5.0+
- Python 3.12 with virtual environment set up in `env/` directory
- Internet connection for browser testing
- Ports 8000 and 8001 available (for memory server and main server)

## Pre-Test Setup

1. Ensure the project is in a clean state:
   ```bash
   git status  # Should show no uncommitted changes except new files
   ```

2. Verify directory structure:
   ```
   project_root/
   ├── scripts/
   │   └── launch_web_runner.ps1
   ├── 启动网页版.bat
   ├── 启动网页版_持久化.bat
   ├── memory_server.py
   ├── main_server.py
   └── env/
       └── python.exe
   ```

3. Verify log directory can be created:
   - `logs/` directory should not exist initially
   - Script will create it automatically

## Test Scenario 1: Standard Mode Startup

### Objective
Verify that the standard startup batch file launches both servers and allows closing the launcher window without killing servers.

### Steps

1. **Start the launcher**
   - Double-click `启动网页版.bat`
   - PowerShell window appears with startup progress

2. **Verify startup messages** (you should see):
   ```
   ============================================================
   正在启动 Project Lanlan 网页版应用程序
   ============================================================

   启动内存服务器...
   内存服务器已启动 (PID: XXXXX)
   启动主服务器...
   主服务器已启动 (PID: YYYYY)

   ============================================================
   服务已启动！
   
   请手动打开浏览器访问：
   http://127.0.0.1:8000
   
   日志文件位置：
   内存服务器: logs\memory_server.log
   主服务器: logs\main_server.log
   
   要停止所有服务，请关闭此窗口或按 Ctrl+C
   ============================================================
   ```

3. **Verify PIDs are captured**
   - Note down the two process IDs shown in messages
   - Open Task Manager (Ctrl+Shift+Esc)
   - Verify two `python.exe` processes are running with matching PIDs

4. **Open browser**
   - Open browser to `http://127.0.0.1:8000`
   - Verify the web interface loads

5. **Close browser**
   - Close the browser window/tab
   - **VERIFY**: PowerShell window remains open
   - **VERIFY**: Both Python processes still running in Task Manager

6. **Close PowerShell window**
   - Close the PowerShell launcher window
   - PowerShell should display cleanup messages:
     ```
     正在清理资源并关闭所有服务...
     已停止进程: PID XXXXX (python)
     已停止进程: PID YYYYY (python)
     
     清理完成。2 个应用程序进程已停止。
     
     感谢使用 Project Lanlan！
     ```
   - PowerShell window closes

7. **Verify cleanup**
   - **VERIFY**: Both Python processes are gone from Task Manager
   - **VERIFY**: No orphaned processes remain

8. **Check log files**
   - Verify `logs/` directory was created
   - Verify `logs/memory_server.log` contains memory server output
   - Verify `logs/main_server.log` contains main server output
   - Verify both logs start with session timestamp

### Expected Result
✅ Both servers start, remain running when browser closes, and cleanly stop when launcher closes

---

## Test Scenario 2: Persistent Mode Startup

### Objective
Verify that the persistent startup batch file passes the --enable-shutdown flag to memory server and behaves the same for process management.

### Steps

1. **Start the launcher**
   - Double-click `启动网页版_持久化.bat`
   - PowerShell window appears

2. **Verify startup** (same messages as Test 1)

3. **Verify --enable-shutdown flag was passed**
   - Check `logs/memory_server.log`
   - Should contain indication that --enable-shutdown flag was accepted
   - Or check for expected behavior difference vs standard mode

4. **Follow same steps as Test 1**
   - Open browser, verify connection
   - Close browser, verify servers continue
   - Close launcher, verify cleanup

### Expected Result
✅ Persistent mode operates identically but with --enable-shutdown flag passed to memory server

---

## Test Scenario 3: Ctrl+C Interrupt

### Objective
Verify that pressing Ctrl+C in the PowerShell window gracefully shuts down both servers.

### Steps

1. **Start the launcher**
   - Double-click `启动网页版.bat`
   - Wait for startup completion

2. **Verify servers are running**
   - Both PIDs logged
   - Both processes visible in Task Manager

3. **Press Ctrl+C**
   - Click in the PowerShell window
   - Press Ctrl+C

4. **Verify graceful shutdown**
   - PowerShell should show cleanup messages:
     ```
     正在清理资源并关闭所有服务...
     已停止进程: PID XXXXX (python)
     已停止进程: PID YYYYY (python)
     ```
   - Both processes should be gone from Task Manager
   - No error messages should appear

### Expected Result
✅ Ctrl+C gracefully terminates both servers without errors

---

## Test Scenario 4: Server Partial Failure

### Objective
Verify that if one server fails to start, the other starts successfully and provides appropriate warning messages.

### Steps

1. **Simulate failure** (optional, requires modification):
   - Temporarily rename or move one of the server files
   - Or modify one server file to have a syntax error

2. **Start the launcher**
   - Double-click `启动网页版.bat`

3. **Verify warning message**
   - Should see warning about failed startup
   - Should see other server still starts successfully
   - Launcher should not exit prematurely

4. **Check log files**
   - The failed server's log should contain error messages
   - The successful server's log should contain normal startup messages

5. **Restore server file**
   - Fix the intentional failure
   - Close launcher window

### Expected Result
✅ Partial failures are handled gracefully with appropriate warnings

---

## Test Scenario 5: Log File Generation

### Objective
Verify that log files are created and contain expected output.

### Steps

1. **Delete logs directory** (if exists from previous tests)
   ```bash
   rmdir /s /q logs
   ```

2. **Start the launcher**
   - Double-click `启动网页版.bat`
   - Wait for startup completion

3. **Verify logs directory created**
   ```bash
   dir logs\
   ```
   Should show:
   - `memory_server.log`
   - `main_server.log`

4. **Check log file contents**
   - Open `logs/memory_server.log` in a text editor
   - Should start with: `=== Session started at YYYY-MM-DD HH:MM:SS ===`
   - Should contain memory server startup messages

   - Open `logs/main_server.log` in a text editor
   - Should start with: `=== Session started at YYYY-MM-DD HH:MM:SS ===`
   - Should contain main server startup messages

5. **Verify encoding**
   - Files should be UTF-8 encoded
   - Chinese characters should display correctly

6. **Close launcher and check logs again**
   - Logs should still exist and be readable
   - Logs should contain complete output from both servers

### Expected Result
✅ Log files are created, properly encoded, and contain expected output

---

## Test Scenario 6: Browser Reconnection

### Objective
Verify that after closing the browser, you can reconnect without restarting services.

### Steps

1. **Start the launcher**
   - Double-click `启动网页版.bat`
   - Wait for startup

2. **Open browser**
   - Navigate to `http://127.0.0.1:8000`
   - Verify web interface loads and functions

3. **Close browser**
   - Close the browser window
   - **VERIFY**: PowerShell window remains open and running

4. **Reopen browser**
   - Open a new browser window
   - Navigate to `http://127.0.0.1:8000`
   - **VERIFY**: Web interface loads without any server restart
   - **VERIFY**: Session state is maintained (if applicable)

5. **Repeat browser close/open cycle**
   - Try 2-3 more times to ensure stability

6. **Close launcher**
   - Close PowerShell window
   - All cleanup messages appear

### Expected Result
✅ Browser can reconnect multiple times without server restart

---

## Test Scenario 7: Multiple Launches

### Objective
Verify that launching the script multiple times doesn't cause port conflicts or other issues.

### Steps

1. **Launch and close** (Test Scenario 1)
   - Complete a full launch and graceful shutdown

2. **Immediately relaunch**
   - Without waiting, double-click launcher script again
   - Both servers should start normally

3. **Verify no port conflicts**
   - No error messages about ports in use
   - Log files show successful startup

4. **Close and repeat**
   - Close launcher
   - Relaunch immediately
   - Verify successful startup again

### Expected Result
✅ Multiple sequential launches work without conflicts

---

## Test Scenario 8: Path Resolution

### Objective
Verify that the script correctly resolves paths regardless of where it's launched from.

### Steps

1. **Launch from project root**
   - Double-click `启动网页版.bat` directly
   - Should work normally

2. **Launch from subdirectory**
   - Not applicable for batch files (they use `%~dp0`)

3. **Launch with long path**
   - Move project to a path with spaces and special characters
   - Double-click launcher
   - Should still work correctly

4. **Verify path handling**
   - Check startup messages for correct Python executable path
   - Check log files are created in correct `logs/` directory

### Expected Result
✅ Paths are resolved correctly regardless of location

---

## Automated Verification Checklist

After completing all manual tests, verify:

- [ ] Standard mode launches both servers
- [ ] Persistent mode passes --enable-shutdown flag
- [ ] Closing browser doesn't kill servers
- [ ] Closing launcher window kills both servers
- [ ] Ctrl+C interrupts gracefully
- [ ] Log files are created with proper encoding
- [ ] Both servers appear in Task Manager with correct PIDs
- [ ] No orphaned processes remain after shutdown
- [ ] Browser can reconnect without server restart
- [ ] Multiple sequential launches work
- [ ] Path resolution works correctly
- [ ] Error messages are clear and helpful
- [ ] Cleanup messages display on shutdown
- [ ] No port conflicts on relaunch

---

## Troubleshooting During Testing

### Issue: "Python executable not found"
- Ensure `env/python.exe` exists
- Check Windows PATH environment variable
- Verify Python installation in virtual environment

### Issue: Port 8000 already in use
- Check for existing Python processes in Task Manager
- Run `netstat -ano | findstr :8000` to see what's using the port
- Restart or move project to different port

### Issue: PowerShell script won't execute
- Check ExecutionPolicy: `powershell -Command "Get-ExecutionPolicy"`
- May need admin privileges to change policy
- Batch file uses `-ExecutionPolicy Bypass` so should work without admin

### Issue: Logs not being created
- Check `logs/` directory permissions
- Verify project has write access
- Check disk space

### Issue: Servers fail to start
- Check `memory_server.py` and `main_server.py` syntax
- Verify Python environment has required packages
- Check `config/api.py` for missing API keys

---

## Success Criteria

The launcher implementation is considered successful when:

1. **Startup**: Both servers start without errors in < 15 seconds
2. **Logging**: Both stdout/stderr are captured to log files
3. **Process Management**: Process IDs are captured and tracked
4. **Cleanup**: Closing launcher window terminates both processes
5. **Interrupt**: Ctrl+C gracefully terminates services
6. **Browser**: Web interface is accessible and functional
7. **Persistence**: Services continue running after browser closes
8. **Reconnection**: Browser can reconnect without server restart
9. **Messages**: User sees clear status messages at each step
10. **Robustness**: No errors, warnings, or orphaned processes

---

## Performance Baseline

When running the launcher, expect:

- **Startup time**: ~10 seconds for both servers to initialize
- **Memory usage**: 50-200 MB per server depending on load
- **CPU usage**: Minimal when idle, peaks during startup
- **Log file growth**: ~100 KB per hour of operation per server
- **Browser response time**: < 1 second for page loads

---

## Next Steps After Testing

If all tests pass:
1. Commit changes to `feat/revise-persistent-runner-launcher` branch
2. Update CHANGES.md with launcher architecture details
3. Notify users about new launcher via release notes
4. Consider automated tests for launcher health checks
5. Monitor for edge cases in production

If tests fail:
1. Document failure details
2. Review PowerShell script for issues
3. Check Windows PowerShell version compatibility
4. Test on different Windows versions if possible
5. Iterate on script improvements
