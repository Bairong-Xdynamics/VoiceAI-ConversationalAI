# 百语智能语音通话 Android SDK

> 轻量级实时智能语音对话开发工具包，基于 WebRTC 技术，为 Android 应用快速集成高质量智能语音交互能力。

## 产品概述
百语智能语音通话 Android SDK 封装了服务端连接、音频采集播放、对话控制等底层复杂逻辑，帮助开发者仅需 10 分钟即可为 Android 应用接入端到端的实时语音对话能力。
SDK 深度对接百语平台智能体机器人，适用于智能客服、语音助手、智能外呼等多种业务场景。

## 主要特性
- 🎤 **开箱即用**：封装 WebRTC、音频采集与播放、连接管理等底层细节
- 🔐 **凭证认证**：使用 robotKey + robotToken 安全接入百语平台智能体
- 🎙️ **实时语音对话**：双向流式语音识别与合成，低延迟自然交互
- 🛑 **打断支持**：可随时打断机器人回复，对话流程更自然
- 🔇 **音频控制**：支持动态静音 / 取消静音麦克风
- 📡 **完整事件系统**：提供会话状态、消息流转、错误等丰富事件通知
- 📱 **原生适配**：支持 Android 7.0 及以上系统，兼容主流 ABI 架构

## 接入前提
使用本 SDK 前，您需要：

1. 在 [百融百语平台](https://alidocs.dingtalk.com/i/nodes/QBnd5ExVEanmejPpT29ZQ1R7VyeZqMmz) 创建智能体 Agent（Robot）
2. 通过 API 方式发布智能体，获取 `robotKey` 和 `robotToken`
3. 应用目标系统版本不低于 Android 7.0（API 24）

> ⚠️ `robotKey` 和 `robotToken` 为敏感凭证，请妥善保管，避免泄露造成计费损失。生产环境建议通过服务端换取临时凭证，严禁在客户端硬编码。

## 快速开始

### 1. 加载 SDK
将 `BR_AI_Voice_RTC_x.x.x.aar` 放入宿主模块的 `libs/` 目录，在 `build.gradle.kts` 中添加依赖：

```kotlin
dependencies {
    implementation(files("libs/BR_AI_Voice_RTC_x.x.x.aar"))
}
```

> 说明：AAR 内部已携带 `consumer-rules.pro` 混淆规则，宿主工程开启 R8/混淆时会自动合并，无需手动配置。

### 2. 权限配置
AAR 的 `AndroidManifest.xml` 已声明基础权限（网络、音频等），宿主工程通常无需重复声明。

**运行时动态申请**：
Android 6.0（API 23）起，麦克风权限需运行时动态申请：
```xml
<!-- 必须：麦克风权限 -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

**可选权限**（Android 12 及以上，蓝牙音频路由按需开启）：
```xml
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
```

> AAR 已内置权限：`INTERNET`、`RECORD_AUDIO`、`MODIFY_AUDIO_SETTINGS`、`ACCESS_NETWORK_STATE`、`ACCESS_WIFI_STATE`

### 3. 基本用法

```kotlin
import com.brgroup.voice.ai.ChatClient
import com.brgroup.voice.ai.ChatEvent
import com.brgroup.voice.ai.ChannelMessage
import com.brgroup.voice.ai.ErrorMessage

// 1. 确保已获取麦克风权限后，构造客户端实例
val client = ChatClient(
    context = applicationContext,
    robotKey = "your_robot_key",      // 从百语平台获取
    robotToken = "your_robot_token",  // 从百语平台获取
    userName = "unique-user-id"       // 唯一用户标识
)

// 2. 注册事件监听
client.on(ChatEvent.SESSION_STARTED) { _, _ ->
    println("会话已开始")
}

client.on(ChatEvent.ROBOT_MESSAGE) { _, data ->
    if (data is ChannelMessage) {
        println("机器人: ${data.text}")
    }
}

client.on(ChatEvent.ERROR) { _, data ->
    if (data is ErrorMessage) {
        println("错误: ${data.code} - ${data.errMsg}")
    }
}

// 3. 启动语音对话
client.startVoiceChat()

// 4. 页面销毁时释放资源
client.stopVoiceChat()
client.removeAll()
```

## 高级用法

### 完整事件监听

```kotlin
val client = ChatClient(context, robotKey, robotToken, userName = "user-123")

// 会话生命周期
client.on(ChatEvent.SESSION_STARTED) { _, _ -> }
client.on(ChatEvent.SESSION_ENDED) { _, _ -> }

// 消息事件
client.on(ChatEvent.USER_MESSAGE) { _, data ->
    if (data is ChannelMessage) {
        // data.text 文本, data.final 是否最终结果, data.rawJson 原始数据
    }
}
client.on(ChatEvent.ROBOT_MESSAGE) { _, data ->
    if (data is ChannelMessage) {
        // 机器人回复消息
    }
}

// 音频状态
client.on(ChatEvent.AUDIO_MUTED) { _, _ -> }
client.on(ChatEvent.AUDIO_UNMUTED) { _, _ -> }

// 机器人进房 / 离房
client.on(ChatEvent.ROBOT_JOINED) { _, _ -> }
client.on(ChatEvent.ROBOT_LEFT) { _, _ -> }

// 监听所有事件（调试用）
client.onAny { eventName, data ->
    println("[$eventName] $data")
}
```

### 对话控制

```kotlin
// 打断机器人当前回复
client.interrupt()

// 静音麦克风
client.setAudioEnabled(enabled = false)

// 取消静音
client.setAudioEnabled(enabled = true)

// 结束语音对话
client.stopVoiceChat()
```

### 完整示例（自动打断 + 结束）

```kotlin
import com.brgroup.voice.ai.ChatClient
import com.brgroup.voice.ai.ChatEvent
import android.os.Handler
import android.os.Looper

val client = ChatClient(
    context = applicationContext,
    robotKey = BuildConfig.ROBOT_KEY,
    robotToken = BuildConfig.ROBOT_TOKEN,
    userName = "demo-user-1"
)

client.on(ChatEvent.SESSION_STARTED) { _, _ -> println("会话开始") }
client.on(ChatEvent.ROBOT_MESSAGE) { _, data ->
    if (data is ChannelMessage) println("机器人: ${data.text}")
}
client.on(ChatEvent.ERROR) { _, data ->
    if (data is ErrorMessage) println("错误: ${data.errMsg}")
}

// 启动对话
client.startVoiceChat()

// 5 秒后打断，10 秒后结束并释放
Handler(Looper.getMainLooper()).postDelayed({ client.interrupt() }, 5000)
Handler(Looper.getMainLooper()).postDelayed({
    client.stopVoiceChat()
    client.removeAll()
}, 10000)
```

## API 参考

### ChatClient
客户端主类，负责会话创建、语音控制与事件分发。

#### 构造器

```kotlin
ChatClient(
    context: Context,
    robotKey: String,
    robotToken: String,
    userName: String
)
```

**参数说明**
- `context: Context` – 应用上下文，建议使用 `applicationContext`
- `robotKey: String` – 百语平台智能体 Key
- `robotToken: String` – 百语平台智能体 Token
- `userName: String` – 唯一用户标识（必填，不同用户必须不同）

#### 方法

| 方法名 | 返回值 | 描述 |
|--------|--------|------|
| `startVoiceChat()` | `Unit` | 启动语音对话，建立 RTC 连接 |
| `stopVoiceChat()` | `Unit` | 结束语音对话，释放所有资源 |
| `interrupt()` | `Boolean` | 打断机器人回复，成功返回 `true` |
| `setAudioEnabled(enabled: Boolean)` | `Unit` | 开启 / 关闭麦克风采集 |
| `getSdkVersion()` | `String` | 获取当前 SDK 版本号 |
| `on(event, listener)` | `Unit` | 注册指定事件监听器 |
| `onAny(listener)` | `Unit` | 注册全局事件监听器 |
| `removeAll()` | `Unit` | 移除所有事件监听 |

### ChatEvent
事件枚举常量，推荐使用枚举而非硬编码字符串。

| 枚举值 | 触发时机 | 数据类型 |
|--------|----------|----------|
| `SESSION_STARTED` | 本端成功加入 RTC 频道 | null |
| `SESSION_ENDED` | 会话结束流程完成 | null |
| `USER_MESSAGE` | 用户语音识别结果（流式） | `ChannelMessage` |
| `ROBOT_MESSAGE` | 机器人回复文本（流式） | `ChannelMessage` |
| `AUDIO_MUTED` | 麦克风静音生效 | null |
| `AUDIO_UNMUTED` | 麦克风取消静音生效 | null |
| `ROBOT_JOINED` | 远端智能体进房 | null |
| `ROBOT_LEFT` | 远端智能体离房 | null |
| `ERROR` | 发生错误时触发 | `ErrorMessage` |

#### ChannelMessage 数据结构
- `text: String` – 消息文本内容
- `final: Boolean` – 是否为最终结果（`false` 增量，`true` 本句结束）
- `speakerId: String` – 说话人标识（助手模式使用）
- `rawJson: String` – 原始 JSON 字符串

#### ErrorMessage 数据结构
- `code: Int` – 错误码
- `errMsg: String` – 错误描述

## 错误码说明

| 错误码 | 详细描述 |
|--------|----------|
| 3001 | 参数校验错误（入参为空、格式非法或缺失必要字段） |
| 3002 | 当前设备无可用网络连接 |
| 3003 | SDK 内部网络请求异常（网络中断、服务端返回非 2xx） |
| 3004 | 未获取麦克风权限（RECORD_AUDIO） |
| 3005 | 不支持的渠道或运行平台 |
| 3006 | 语音引擎初始化异常 |
| 3007 | 本端加入 RTC 频道异常 |
| 3008 | 本端离开 RTC 频道异常 |
| 3009 | 调用 `interrupt()` 时语音连接尚未建立 |
| 3010 | 业务指令序列化失败 |
| 3011 | 发送指令或业务数据流失败 |
| 3012 | 语音引擎未初始化时调用 SDK 方法 |
| 3013 | 麦克风开关状态设置失败 |
| 3014 | SDK 底层未知异常 |
| 3015 | 发起会话过程中连接异常中断 |
| 3016 | 底层接收 RTC 数据流异常 |
| 3017 | 创建业务数据流通道失败 |
| 3018 | 本端进房后远端智能体上线超时 |
| 3019 | 远端智能体下线且重连超时 |
| 3020 | 业务数据流 JSON 解析失败 |
| 3021 | 调用流程互斥（重复发起未完成的启动请求） |

## 兼容性说明

| 项 | 说明 |
|----|------|
| Android 系统 | minSdk 24（Android 7.0 及以上） |
| 开发语言 | Kotlin，AAR 已包含 Kotlin 与协程依赖 |
| ABI 架构 | arm64-v8a、armeabi-v7a |
| 运行要求 | 设备具备麦克风与网络连接 |

## 运行示例
Demo 工程包含基础接入示例页面

将 Demo 导入 Android Studio，配置 `robotKey` 与 `robotToken` 后即可运行。
