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
1. 启动Memory Server作为后台进程
2. 启动Main Server作为后台进程
3. 自动打开浏览器访问应用
4. 保持命令行窗口打开
5. 当用户关闭窗口时，所有后台进程继续运行

#### 关键特性
- **持久化** - 即使关闭浏览器标签页，后台服务仍在运行
- **独立性** - 服务器运行独立于浏览器实例
- **便利性** - 只需关闭主窗口即可停止所有服务

## 技术细节

### 文本流处理流程 (完整管道)
```
用户输入文本
↓
sendTextMessage() 获取文本，设置 textRequestPending = true，禁用发送按钮
↓
WebSocket 发送 stream_data 消息（input_type='text'）
↓
main_server.py 路由到 session_manager.stream_data()
↓
normalize_text() 规范化处理
↓
获取 text_response_lock，检查 text_response_pending 状态
↓
session.stream_text() 发送到Core API (input_text_buffer.append 事件)
↓
session.commit_text_buffer() 立即提交文本缓冲区 (input_text_buffer.commit 事件)
↓
发送状态消息 "正在处理文本输入..."
↓
session.create_response() 无自定义指令地请求响应
↓
Core API处理文本并流式返回响应
↓
response.text.delta 事件：前端接收并显示文本响应
↓
response.audio.delta 事件：前端接收并播放音频响应（如果启用本地TTS）
↓
response.done 事件：响应完成，触发 handle_response_complete()
↓
清除 text_response_pending = false
↓
前端接收 'turn end' 系统消息，清除 textRequestPending，重新启用发送按钮
```

### API事件格式
文本输入使用以下事件格式：

**追加文本到缓冲区：**
```json
{
    "type": "input_text_buffer.append",
    "text": "用户输入的文本"
}
```

**提交文本缓冲区：**
```json
{
    "type": "input_text_buffer.commit"
}
```

**请求响应（不带自定义指令）：**
```json
{
    "type": "response.create",
    "response": {
        "modalities": ["text", "audio"]
    }
}
```

## 测试步骤

### 文本输入功能测试
1. 启动应用（使用任意启动脚本）
2. 在聊天窗口底部找到文本输入框
3. 输入文本消息（例如："你好")
4. 点击"发送"按钮或按Enter键
5. 观察：
   - 用户消息出现在聊天窗口中
   - 发送按钮被禁用（灰显）
   - 状态文本更新为 "正在处理您的消息..."
6. 等待AI的文本和音频响应
7. 观察：
   - AI的消息出现在聊天窗口中
   - 音频开始播放（如果启用）
   - 状态文本更新为 "回复已收到，可继续发送消息"
   - 发送按钮被重新启用

### 多消息连续测试
1. 快速发送3-4条文本消息
2. 验证行为：
   - 第二条消息会显示 "请等待上一条消息的回复..."
   - 发送按钮保持禁用，直到上一条消息完全处理
   - 每条消息都会收到完整的文本+音频响应

### Windows持久化功能测试
1. 运行 `启动网页版_持久化.bat`
2. 浏览器应自动打开应用页面
3. 关闭浏览器标签页或整个浏览器窗口
4. 重新打开浏览器访问 http://127.0.0.1:8000
5. 应用仍然响应（服务未停止）
6. 关闭启动脚本的命令行窗口
7. 服务停止

## 文件修改列表

- `templates/index.html` - 取消注释并增强文本输入UI
- `static/app.js` - 实现文本输入处理逻辑，添加请求待机状态管理
- `main_helper/omni_realtime_client.py` - 添加stream_text()和commit_text_buffer()方法，修改create_response()支持无指令模式
- `main_helper/core.py` - 在stream_data()中添加完整的文本处理管道，包括缓冲区提交和响应创建，添加文本响应锁和待机状态
- `main_server.py` - 支持文本输入的会话启动
- `启动网页版.bat` - 改进启动逻辑
- `启动网页版_持久化.bat` - 新的持久化启动脚本
- `.gitignore` - 创建标准gitignore文件

## 注意事项和故障排除

### 核心特性
1. **文本缓冲区提交** - 文本必须通过 `input_text_buffer.commit` 事件才能被API处理
2. **请求去重** - 使用异步锁 (`text_response_lock`) 和 `text_response_pending` 标志防止重叠请求
3. **UI反馈** - 发送按钮自动禁用/启用，状态文本实时更新用户体验

### 浏览器兼容性
- 文本输入框在所有现代浏览器中都能工作（Chrome, Firefox, Safari, Edge）
- 确保WebSocket连接正常建立

### 常见问题

**Q: 发送文本后没有响应？**
- 检查服务器日志中是否有错误信息
- 验证WebSocket连接状态（查看浏览器控制台）
- 确保Core API服务正在运行并可访问
- 检查API Key是否有效

**Q: 发送按钮长时间禁用？**
- 这通常表示上一个请求的响应未完成
- 检查服务器日志中的 "response.done" 事件
- 尝试刷新页面并重新启动会话

**Q: 状态文本显示 "正在处理文本输入..." 但没有响应？**
- API可能在处理文本，检查网络延迟
- 如果持续超过30秒，服务器可能有问题，检查日志
- 尝试重置会话

**Q: 文本框清空后收不到响应？**
- 确保会话已正确启动（status应显示 "连接已建立...")
- 检查 `text_response_pending` 状态是否正确复位
- 查看浏览器控制台是否有JavaScript错误

### API兼容性
- `input_text_buffer.append` 事件需要Core API支持
- `input_text_buffer.commit` 事件触发API处理文本输入
- `response.create` 支持不带自定义指令的调用（使用会话默认指令）

### 文本处理
- 输入的文本会被规范化（移除特殊字符、修复标点等）
- 规范化失败会记录错误并返回状态消息给用户

### Windows特定
- 持久化启动脚本针对Windows系统优化
- 后台服务在单独的窗口中运行，不依赖浏览器生命周期

## 未来改进方向

- 添加自动完成/建议功能
- 支持Markdown富文本输入
- 添加消息历史搜索
- 实现消息编辑功能
- 跨设备同步支持
