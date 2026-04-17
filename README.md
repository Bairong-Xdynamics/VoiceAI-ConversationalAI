# VoiceAI-ConversationalAI

[License: MIT](https://opensource.org/licenses/MIT)

> 一站式智能语音对话解决方案 —— 为 Web、Android、iOS 提供轻量级实时语音交互 SDK，快速集成 AI 智能体语音对话能力。

## 特性

- 🎤 **全平台覆盖** – 提供 Web (JavaScript/TypeScript)、Android (Kotlin/Java)、iOS (Swift) SDK
- 🔐 **安全认证** – 支持平台密钥/令牌认证，生产环境可动态换取临时凭证
- 🎙️ **实时语音对话** – 基于 WebRTC 的低延迟双向语音识别与合成
- 🛑 **打断支持** – 随时打断机器人回复，实现自然对话体验
- 🔇 **音频控制** – 动态静音/取消静音麦克风
- 📡 **丰富事件系统** – 会话生命周期、消息流、错误等完整事件通知
- 📦 **开箱即用** – 封装底层 WebRTC、音频采集播放、连接管理等细节

## 各平台 SDK 概览


| 平台      | 语言                      | 核心类               | 状态     |
| ------- | ----------------------- | ----------------- | ------ |
| Web     | JavaScript / TypeScript | `ChatClient`      | ✅ 可用   |
| Android | Kotlin / Java           | `VoiceChatClient` | 🚧 开发中 |
| iOS     | Swift                   | `VoiceChatClient` | 🚧 开发中 |


> 具体 API 文档和使用示例请见各子目录下的 README。

## 通用接入前提

1. 在智能语音对话平台（百融百工）创建 Agent，获取 `robotKey` 和 `robotToken`
2. 确保客户端运行在安全环境：
  - Web：HTTPS 或 localhost
  - Android / iOS：正常网络权限
3. 处理麦克风权限请求（用户授权）

## 许可证

MIT © VoiceAI Team