# Windows 持久化模式修改说明

## 概述
本次修改确保在 Windows 下启动应用后：
1. **不会自动打开浏览器** - 用户需要手动打开浏览器访问应用
2. **关闭浏览器后服务继续运行** - 后台服务独立运行，只有关闭启动脚本窗口才会停止

## 修改内容

### 1. 启动脚本修改

#### 文件：`启动网页版.bat`
- **移除**: `--open-browser --page index` 参数
- **改为**: 不带参数启动 main_server.py
- **用户提示**: 显示手动访问 URL 的指引 (http://127.0.0.1:8000)

#### 文件：`启动网页版_持久化.bat`
- **移除**: `--open-browser --page index` 参数
- **改为**: 不带参数启动 main_server.py
- **用户提示**: 更新说明文字，提示手动打开浏览器

**修改的启动命令:**
```bat
REM 原始（会自动打开浏览器）:
start "" /B "%~dp0env\python.exe" "%~dp0main_server.py" --open-browser --page index

REM 修改后（不自动打开）:
start "" /B "%~dp0env\python.exe" "%~dp0main_server.py"
```

### 2. 后端API修改

#### 文件：`main_server.py`

**修改1: beacon_shutdown 端点 (第713-723行)**
```python
# 原始逻辑：如果启用了浏览器模式，接收beacon信号就关闭服务器
if current_config['browser_mode_enabled']:
    asyncio.create_task(shutdown_server_async())
    return {"success": True}

# 修改后：禁用自动关闭，始终返回继续运行
logger.info("收到beacon信号，但持久化模式下服务将继续运行")
return {"success": True, "message": "收到信号，服务持续运行中"}
```

**修改2: 添加新端点 beacon_page_closed (第726-732行)**
```python
@app.post("/api/beacon/page_closed")
async def beacon_page_closed():
    """处理页面关闭通知 - 服务继续运行"""
    logger.info("浏览器页面已关闭，但服务器保持运行中（持久化模式）")
    return {"success": True, "message": "页面已关闭，服务继续运行"}
```

### 3. 前端修改

#### 文件：`templates/index.html` (第442-465行)

**修改: Beacon 功能**
```javascript
// 原始逻辑：发送 /api/beacon/shutdown 信号尝试关闭服务器
navigator.sendBeacon('/api/beacon/shutdown', ...)

// 修改后：发送 /api/beacon/page_closed 通知信号（不导致关闭）
navigator.sendBeacon('/api/beacon/page_closed', ...)
console.log('页面已关闭，但服务器继续运行（持久化模式）')
```

## 工作流程

### 启动流程
```
1. 用户运行启动脚本
2. 后台启动 Memory Server
3. 后台启动 Main Server（不打开浏览器）
4. 显示"服务已启动"提示
5. 显示"请手动打开浏览器访问 http://127.0.0.1:8000"
6. 用户手动打开浏览器
```

### 关闭浏览器流程
```
1. 用户关闭浏览器标签页或浏览器窗口
2. 页面 beforeunload/unload 事件触发
3. 发送 /api/beacon/page_closed 信号
4. 后端记录日志但不关闭服务
5. 服务继续运行
```

### 关闭服务流程
```
1. 用户关闭启动脚本窗口（按Ctrl+C或关闭窗口）
2. 所有后台进程被终止
3. 服务完全停止
```

## 用户使用指南

### 启动应用
1. 双击运行 `启动网页版.bat` 或 `启动网页版_持久化.bat`
2. 等待提示"服务已启动"
3. 手动打开浏览器（Chrome、Firefox、Edge等）
4. 在地址栏输入 `http://127.0.0.1:8000`
5. 回车访问应用

### 重新打开浏览器
1. 关闭浏览器或浏览器标签页
2. 重新打开浏览器，访问 `http://127.0.0.1:8000`
3. 应用正常运行（服务从未停止）

### 停止应用
1. 关闭启动脚本的命令行窗口
2. 或在命令行窗口中按 `Ctrl+C`
3. 所有服务停止

## 关键改变点

| 功能点 | 原始行为 | 现在行为 |
|-------|--------|--------|
| 启动方式 | 自动打开浏览器 | 需要手动打开浏览器 |
| 浏览器关闭 | 触发服务器关闭 | 服务继续运行 |
| 服务停止 | 只能通过关闭浏览器或Ctrl+C | 只能通过关闭启动窗口或Ctrl+C |
| beacon信号 | shutdown (关闭) | page_closed (通知) |

## 优势

✅ **更稳定** - 浏览器崩溃不会导致服务停止  
✅ **更灵活** - 可以随时重新打开浏览器  
✅ **更直观** - 用户清楚知道何时启动和停止服务  
✅ **更安全** - 防止意外关闭服务  
✅ **更易用** - 遵循传统应用的启动/停止模式  

## 兼容性

- ✅ Windows 10/11
- ✅ 所有现代浏览器 (Chrome, Firefox, Edge, Safari等)
- ✅ 支持多浏览器实例访问
- ✅ 支持WebSocket持续连接

## 故障排除

### 问题1: 启动脚本后什么都没有发生
**解决**: 检查命令行窗口是否仍在运行，可能需要等待几秒钟服务启动完成

### 问题2: 无法访问应用
**解决**: 
- 确认启动脚本窗口仍在运行
- 尝试在浏览器中直接输入 http://127.0.0.1:8000
- 检查Windows防火墙是否阻止了8000端口

### 问题3: 关闭浏览器后访问不了
**解决**: 重新打开浏览器，访问 http://127.0.0.1:8000，服务应该继续运行

## 相关文档
- TEXT_INPUT_IMPLEMENTATION.md - 文本输入功能说明
- USAGE_GUIDE.md - 用户使用指南
- 启动网页版.bat - 标准启动脚本
- 启动网页版_持久化.bat - 持久化启动脚本
