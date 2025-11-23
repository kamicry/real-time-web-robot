# 文本输入功能和Windows持久化运行器实现

## 概述
本实现为Project Lanlan添加了两项关键功能：
1. **文本输入功能** - 允许用户通过文字输入而不仅限于语音
2. **Windows持久化Web运行器** - 确保后台服务持续运行，直到主窗口关闭

## 实现详情

### 1. 文本输入功能

#### 前端修改 (templates/index.html)
- 取消注释了文本输入框和发送按钮
- 添加了CSS样式以改进用户体验（focus状态、hover效果等）

#### 前端逻辑 (static/app.js)
- 新增 `sendTextMessage()` 函数处理文本发送
- 支持点击按钮或按Enter键发送消息
- 自动启动会话（如果未启动）
- 消息显示在聊天窗口中

#### API支持 (main_helper/omni_realtime_client.py)
- 新增 `stream_text()` 方法用于发送文本输入到Core API
- 使用 `input_text_buffer.append` 事件类型

#### 后端处理 (main_helper/core.py)
- 在 `stream_data()` 方法中添加对 `input_type='text'` 的支持
- 对文本进行规范化处理（使用现有的 `normalize_text()` 方法）
- 支持将文本记录到消息缓存（用于热切换场景）

#### WebSocket路由 (main_server.py)
- 更新 `start_session` 处理器以支持 `input_type='text'`
- 允许文本输入启动新的会话

### 2. Windows持久化Web运行器

#### 启动脚本改进

**原始脚本：`启动网页版.bat`**
- 修改为在后台启动服务（使用 `/B` 参数）
- 保持命令行窗口打开，用户需要手动关闭以停止服务

**新增脚本：`启动网页版_持久化.bat`**
- 提供更详细的启动信息
- 更好的错误处理
- 清晰的用户指导

#### 工作原理
1. 启动Memory Server作为后台进程（窗口标题为“Memory Server”，最小化显示）。
2. 启动Main Server作为后台进程（窗口标题为“Main Server”）。
3. 在启动脚本窗口中输出“服务已启动”提示，引导用户**手动**打开浏览器访问 `http://127.0.0.1:8000`。
4. 浏览器关闭时仅发送 `/api/beacon/page_closed` 通知，后台进程保持运行。
5. 只有关闭启动脚本窗口或按 `Ctrl+C` 时，脚本才会调用 `taskkill` 清理两个服务器进程并写入停机日志。

#### 关键特性
- **持久化** - 即使关闭浏览器标签页，后台服务仍在运行
- **独立性** - 服务器运行独立于浏览器实例
- **便利性** - 只需关闭主窗口即可停止所有服务

#### 日志与关闭语义
- “Memory Server”“Main Server”最小化窗口实时输出服务日志，可直接最大化排查异常。
- `lanlan_server_YYYYMMDD.log` 会在项目根目录每日创建/追加，记录 `start_session`、`input_type='text'` 以及模型错误，便于离线诊断。
- 关闭浏览器只会写入一条 `page_closed` 日志，服务继续运行；关闭启动脚本窗口或按 `Ctrl+C` 才会触发 `taskkill` 并停止所有进程。

## 技术细节

### 文本流处理流程
```
用户输入文本
↓
sendTextMessage() 获取文本
↓
WebSocket 发送 stream_data 消息（input_type='text'）
↓
main_server.py 路由到 stream_data()
↓
normalize_text() 规范化处理
↓
session.stream_text() 发送到Core API
↓
API处理并返回响应
↓
前端接收响应并显示
```

### API事件格式
文本输入的WebSocket流程分两个阶段：
1. **会话启动**（自动发送）
```json
{
    "action": "start_session",
    "input_type": "text"
}
```
2. **文本流**（每条用户消息）
```json
{
    "action": "stream_data",
    "input_type": "text",
    "data": "用户输入的文本"
}
```
服务器端会将 `stream_data` 转换成 OpenAI Realtime 兼容的事件：
```json
{
    "type": "input_text_buffer.append",
    "text": "用户输入的文本"
}
```

## 测试步骤

### 文本输入功能测试
1. 双击运行 `启动网页版_持久化.bat`，等待提示“服务已启动”。
2. 手动打开浏览器访问 `http://127.0.0.1:8000`。
3. 在聊天窗口底部输入框输入文本。
4. 点击“发送”或按 Enter，观察状态从“连接已建立”变为“正在对话...”。
5. 确认用户消息立即显示在历史记录中。
6. 打开 `lanlan_server_YYYYMMDD.log`，确认记录了 `start_session` 与 `input_type='text'` 日志。
7. 等待AI回复并确认语音/文字同步输出。

### Windows持久化功能测试
1. 运行 `启动网页版_持久化.bat` 并等待“服务已启动”提示。
2. 手动打开浏览器访问 `http://127.0.0.1:8000`，确认页面连接成功。
3. 关闭浏览器标签页，观察启动脚本窗口仍在运行。
4. 重新打开浏览器访问相同地址，确认会话仍可继续。
5. 查看 `lanlan_server_YYYYMMDD.log`，确认收到 `page_closed` 通知日志。
6. 关闭启动脚本的命令行窗口或按 `Ctrl+C`。
7. 确认“Memory Server”“Main Server”窗口被 `taskkill` 终止，服务完全停止。

## 文件修改列表

- `templates/index.html` - 取消注释并增强文本输入UI
- `static/app.js` - 实现文本输入处理逻辑
- `main_helper/omni_realtime_client.py` - 添加stream_text()方法
- `main_helper/core.py` - 在stream_data()中添加文本处理
- `main_server.py` - 支持文本输入的会话启动
- `启动网页版.bat` - 改进启动逻辑
- `启动网页版_持久化.bat` - 新的持久化启动脚本
- `.gitignore` - 创建标准gitignore文件

## 注意事项

1. **API兼容性** - `input_text_buffer.append` 事件需要Core API支持
2. **浏览器兼容性** - 文本输入框在所有现代浏览器中都能工作
3. **Windows特定** - 持久化启动脚本针对Windows系统优化
4. **文本处理** - 输入的文本会被规范化（移除特殊字符、修复标点等）

## 未来改进方向

- 添加自动完成/建议功能
- 支持Markdown富文本输入
- 添加消息历史搜索
- 实现消息编辑功能
- 跨设备同步支持
