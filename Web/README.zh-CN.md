# 语音通话 JS SDK

> 轻量级的实时智能语音对话 SDK，基于 WebRTC 技术，为 Web 应用快速集成高质量的智能语音交互体验。

## 快速开始

### 1. 安装依赖

使用 pnpm（或 npm）安装 SDK：

```sh
pnpm add @koi-video/voice-realtime-sdk
# 或
npm install @koi-video/voice-realtime-sdk
```

### 2. 基本用法

```javascript
import { ChatClient, VoiceEvents } from '@koi-video/voice-realtime-sdk';

// 初始化客户端（需要先获取 robotKey 和 robotToken）
const client = new ChatClient(
  {
    robotKey: 'your_robot_key',      // 从百工平台获取
    robotToken: 'your_robot_token',  // 从百工平台获取
  },
  {
    userName: 'unique-user-id',      // 唯一用户标识
  }
);

// 注册事件监听
client.on(VoiceEvents.SESSION_CREATED, ({ sessionId }) => {
  console.log('会话已创建', sessionId);
});

client.on(VoiceEvents.ROBOT_MESSAGE, ({ content }) => {
  console.log('机器人:', content);
});

client.on(VoiceEvents.ERROR, (err) => {
  console.error('错误:', err.code, err.message);
});

// 启动语音对话
try {
  const sessionId = await client.startVoiceChat();
  console.log('对话已启动，会话ID:', sessionId);
} catch (error) {
  console.error('启动失败', error);
}
```

## 主要特性

- 🎤 **开箱即用**：封装 WebRTC、音频采集与播放、连接管理等底层细节
- 🔐 **凭证认证**：使用 robotKey + robotToken 安全接入百工平台智能体
- 🎙️ **实时语音对话**：支持双向流式语音识别与合成，低延迟交互
- 🛑 **打断支持**：可随时打断机器人回复，实现更自然的对话体验
- 🔇 **音频控制**：支持动态静音/取消静音麦克风
- 📡 **完整事件系统**：提供会话状态、消息流转、错误等丰富的事件通知
- 🌐 **安全上下文**：需在 HTTPS 或 localhost 环境下运行（浏览器麦克风权限要求）

## 接入前提

使用本 SDK 前，您需要：

1. 在 [百融百工平台](https://alidocs.dingtalk.com/i/nodes/QBnd5ExVEanmejPpT29ZQ1R7VyeZqMmz) 创建智能体 Agent（Robot）
2. 完成 API 方式发布，获取 `robotKey` 和 `robotToken`
3. 确保您的应用运行在安全上下文（HTTPS 或 localhost）中

> ⚠️ `robotKey` 和 `robotToken` 是敏感凭证，请妥善保管，避免泄露造成计费损失。生产环境建议通过服务端换取临时凭证。

## 高级用法

### 完整事件监听

```javascript
import { ChatClient, VoiceEvents } from '@koi-video/voice-realtime-sdk';

const client = new ChatClient({ robotKey, robotToken }, { userName: 'user-123' });

// 监听会话生命周期
client.on(VoiceEvents.SESSION_CREATED, ({ sessionId }) => {});
client.on(VoiceEvents.SESSION_STARTED, ({ sessionId }) => {});
client.on(VoiceEvents.SESSION_ENDED, ({ sessionId, reason }) => {});

// 监听消息
client.on(VoiceEvents.USER_MESSAGE, ({ content, segmentId, raw }) => {
  // raw 包含完整转写信息：role, final, payload 等
});
client.on(VoiceEvents.ROBOT_MESSAGE, ({ content, segmentId, raw }) => {});

// 监听打断事件
client.on(VoiceEvents.INTERRUPT, ({ sessionId }) => {});

// 监听音频静音状态变化
client.on(VoiceEvents.AUDIO_MUTED, ({ sessionId }) => {});
client.on(VoiceEvents.AUDIO_UNMUTED, ({ sessionId }) => {});

// 监听所有事件（调试用）
client.on(VoiceEvents.ALL, (eventName, data) => {
  console.log(`[${eventName}]`, data);
});
```

### 对话控制

```javascript
// 打断机器人当前回复
client.interrupt();

// 静音麦克风（异步）
await client.setAudioEnabled({ bool: false });

// 取消静音
await client.setAudioEnabled({ bool: true });

// 结束语音对话
await client.stopVoiceChat();
```

### 完整示例（带自动打断与结束）

```javascript
import { ChatClient, VoiceEvents } from '@koi-video/voice-realtime-sdk';

const client = new ChatClient(
  {
    robotKey: process.env.ROBOT_KEY,
    robotToken: process.env.ROBOT_TOKEN,
  },
  {
    userName: 'demo-user-1',
  }
);

// 注册事件
client.on(VoiceEvents.SESSION_CREATED, ({ sessionId }) => console.log('会话创建', sessionId));
client.on(VoiceEvents.ROBOT_MESSAGE, ({ content }) => console.log('机器人:', content));
client.on(VoiceEvents.ERROR, (err) => console.error('错误:', err));

// 启动对话
const sessionId = await client.startVoiceChat();
console.log('会话ID:', sessionId);

// 5秒后打断，10秒后结束
setTimeout(() => client.interrupt(), 5000);
setTimeout(() => client.stopVoiceChat(), 10000);
```

## API 参考

### ChatClient

客户端主类，用于创建语音会话、发送语音、控制对话流程。

#### 构造器

```typescript
new ChatClient(credentials: Credentials, options: ClientOptions)
```

- **Credentials**
  - `robotKey: string` – 百工平台智能体 Key
  - `robotToken: string` – 百工平台智能体 Token
- **ClientOptions**
  - `userName: string` – 唯一用户标识（必填，不同用户必须不同）

#### 方法

| 方法名 | 返回值 | 描述 |
|--------|--------|------|
| `startVoiceChat()` | `Promise<string>` | 启动语音对话，返回 `sessionId` |
| `stopVoiceChat()` | `Promise<void>` | 结束当前语音对话，释放资源 |
| `interrupt()` | `void` | 打断机器人正在进行的回复 |
| `setAudioEnabled({ bool })` | `Promise<void>` | 静音 (`bool: false`) 或取消静音 (`bool: true`) |
| `on(event, handler)` | `void` | 注册事件监听器 |

### VoiceEvents

事件名称常量对象，推荐使用而非硬编码字符串。

| 常量 | 值 | 触发时机 |
|------|-----|----------|
| `SESSION_CREATED` | `'SESSION_CREATED'` | HTTP 启动成功，会话就绪；载荷 `{ sessionId }` |
| `SESSION_STARTED` | `'SESSION_STARTED'` | 会话正式开始（WebRTC 连接建立） |
| `SESSION_ENDED` | `'SESSION_ENDED'` | 调用 `stopVoiceChat`、RTC 异常断开或服务端结束；载荷 `{ sessionId, reason }` |
| `USER_MESSAGE` | `'USER_MESSAGE'` | 用户语音识别结果（流式）；载荷 `{ content, segmentId?, raw }` |
| `ROBOT_MESSAGE` | `'ROBOT_MESSAGE'` | 机器人回复文本（流式）；载荷同上 |
| `INTERRUPT` | `'INTERRUPT'` | 对话被打断；载荷 `{ sessionId }` |
| `AUDIO_MUTED` | `'AUDIO_MUTED'` | 静音生效后触发 |
| `AUDIO_UNMUTED` | `'AUDIO_UNMUTED'` | 取消静音生效后触发 |
| `ERROR` | `'ERROR'` | 错误发生；载荷包含 `code`, `message`, `sessionId?` |
| `ALL` | `'ALL'` | 捕获所有事件，回调签名 `(eventName, data)` |

> 其中 `raw` 字段结构示例：
> ```json
> {
>   "role": "user",        // "user" 或 "llm"
>   "final": false,        // false=增量，true=最终结果
>   "text": "我是",
>   "payload": { "emotion": "缓和" }
> }
> ```

## 浏览器兼容性

- 需要支持 WebRTC 的现代浏览器（Chrome、Firefox、Safari、Edge）
- **iOS Safari**：`startVoiceChat()` 必须由用户手势（如点击按钮）触发
- 必须运行在 **HTTPS** 或 **localhost** 环境下（浏览器安全策略）


## 尝试示例

### 在浏览器中

```bash
cd demo
pnpm i
npm run demo
```

## 文档链接

- 待补充