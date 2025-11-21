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
文本输入使用以下事件格式：
```json
{
    "type": "input_text_buffer.append",
    "text": "用户输入的文本"
}
```

## 测试步骤

### 文本输入功能测试
1. 启动应用（使用任意启动脚本）
2. 在聊天窗口底部找到文本输入框
3. 输入文本消息
4. 点击"发送"按钮或按Enter键
5. 确认消息出现在聊天窗口中
6. 等待AI响应

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
