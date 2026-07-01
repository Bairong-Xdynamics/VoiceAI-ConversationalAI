# Baiyu Intelligent Voice Call Android SDK

> A lightweight real-time intelligent voice conversation SDK based on WebRTC, for quickly integrating high-quality voice interaction into Android applications.

## Product Overview
The Baiyu Intelligent Voice Call Android SDK encapsulates low-level logic including server connection, audio capture/playback, and conversation control. Developers can integrate end-to-end real-time voice capabilities into Android apps in just 10 minutes.

Deeply integrated with Baiyu platform agents, it is suitable for intelligent customer service, voice assistants, smart outbound calls and other scenarios.

## Key Features
- 🎤 **Out-of-the-box**: Encapsulates WebRTC, audio processing, connection management and other low-level details
- 🔐 **Credential Auth**: Secure access via `robotKey` + `robotToken`
- 🎙️ **Real-time Conversation**: Bidirectional streaming ASR & TTS with low latency
- 🛑 **Interruption Support**: Interrupt robot replies at any time for natural dialogue
- 🔇 **Audio Control**: Dynamically mute / unmute the microphone
- 📡 **Complete Event System**: Rich events for session state, message flow and errors
- 📱 **Native Support**: Android 7.0+ compatible, supports mainstream ABIs

## Prerequisites
Before using this SDK:

1. Create an Agent (Robot) on the [Bairong Baiyu Platform](https://alidocs.dingtalk.com/i/nodes/QBnd5ExVEanmejPpT29ZQ1R7VyeZqMmz)
2. Publish the agent via API mode to obtain `robotKey` and `robotToken`
3. Target Android 7.0 (API 24) or higher

> ⚠️ `robotKey` and `robotToken` are sensitive credentials. Keep them secure to avoid billing loss. Use server-side temporary tokens in production. **Never hardcode them in client code.**

## Quick Start

### 1. Import SDK
Place `BR_AI_Voice_RTC_x.x.x.aar` into your module's `libs/` directory, then add the dependency in `build.gradle.kts`:

```kotlin
dependencies {
    implementation(files("libs/BR_AI_Voice_RTC_x.x.x.aar"))
}
```

> The AAR includes `consumer-rules.pro`. Rules are merged automatically when R8 / ProGuard is enabled.

### 2. Permissions
Basic permissions (network, audio) are declared inside the AAR's manifest. No duplicate declaration is required.

**Runtime Permission**:
Request microphone permission at runtime on Android 6.0+:
```xml
<!-- Required: Microphone -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

**Optional** (Android 12+, for Bluetooth audio routing):
```xml
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
```

> Built-in permissions: `INTERNET`, `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`

### 3. Basic Usage

```kotlin
import com.brgroup.voice.ai.ChatClient
import com.brgroup.voice.ai.ChatEvent
import com.brgroup.voice.ai.ChannelMessage
import com.brgroup.voice.ai.ErrorMessage

// 1. Create client after microphone permission is granted
val client = ChatClient(
    context = applicationContext,
    robotKey = "your_robot_key",      // from Baiyu Platform
    robotToken = "your_robot_token",  // from Baiyu Platform
    userName = "unique-user-id"       // unique user ID
)

// 2. Register event listeners
client.on(ChatEvent.SESSION_STARTED) { _, _ ->
    println("Session started")
}

client.on(ChatEvent.ROBOT_MESSAGE) { _, data ->
    if (data is ChannelMessage) {
        println("Robot: ${data.text}")
    }
}

client.on(ChatEvent.ERROR) { _, data ->
    if (data is ErrorMessage) {
        println("Error: ${data.code} - ${data.errMsg}")
    }
}

// 3. Start voice chat
client.startVoiceChat()

// 4. Release resources on destroy
client.stopVoiceChat()
client.removeAll()
```

## Advanced Usage

### Full Event Listening

```kotlin
val client = ChatClient(context, robotKey, robotToken, userName = "user-123")

// Session lifecycle
client.on(ChatEvent.SESSION_STARTED) { _, _ -> }
client.on(ChatEvent.SESSION_ENDED) { _, _ -> }

// Messages
client.on(ChatEvent.USER_MESSAGE) { _, data ->
    if (data is ChannelMessage) {
        // data.text, data.final, data.rawJson
    }
}
client.on(ChatEvent.ROBOT_MESSAGE) { _, data ->
    if (data is ChannelMessage) {
        // robot reply
    }
}

// Audio state
client.on(ChatEvent.AUDIO_MUTED) { _, _ -> }
client.on(ChatEvent.AUDIO_UNMUTED) { _, _ -> }

// Agent join / leave
client.on(ChatEvent.ROBOT_JOINED) { _, _ -> }
client.on(ChatEvent.ROBOT_LEFT) { _, _ -> }

// Listen to all events (debug)
client.onAny { eventName, data ->
    println("[$eventName] $data")
}
```

### Conversation Control

```kotlin
// Interrupt current reply
client.interrupt()

// Mute microphone
client.setAudioEnabled(enabled = false)

// Unmute microphone
client.setAudioEnabled(enabled = true)

// End conversation
client.stopVoiceChat()
```

### Complete Example (auto interrupt & end)

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

client.on(ChatEvent.SESSION_STARTED) { _, _ -> println("Session started") }
client.on(ChatEvent.ROBOT_MESSAGE) { _, data ->
    if (data is ChannelMessage) println("Robot: ${data.text}")
}
client.on(ChatEvent.ERROR) { _, data ->
    if (data is ErrorMessage) println("Error: ${data.errMsg}")
}

client.startVoiceChat()

// Interrupt after 5s, end after 10s
Handler(Looper.getMainLooper()).postDelayed({ client.interrupt() }, 5000)
Handler(Looper.getMainLooper()).postDelayed({
    client.stopVoiceChat()
    client.removeAll()
}, 10000)
```

## API Reference

### ChatClient
Main client class for session management and conversation control.

#### Constructor

```kotlin
ChatClient(
    context: Context,
    robotKey: String,
    robotToken: String,
    userName: String
)
```

**Parameters**
- `context: Context` – Application context (use `applicationContext` recommended)
- `robotKey: String` – Agent key from Baiyu Platform
- `robotToken: String` – Agent token from Baiyu Platform
- `userName: String` – Unique user identifier (required, must be unique per user)

#### Methods

| Method | Return | Description |
|--------|--------|-------------|
| `startVoiceChat()` | `Unit` | Start voice chat, establish RTC connection |
| `stopVoiceChat()` | `Unit` | End conversation and release resources |
| `interrupt()` | `Boolean` | Interrupt robot reply, returns `true` on success |
| `setAudioEnabled(enabled: Boolean)` | `Unit` | Enable / disable microphone capture |
| `getSdkVersion()` | `String` | Get current SDK version |
| `on(event, listener)` | `Unit` | Register event listener |
| `onAny(listener)` | `Unit` | Register global event listener |
| `removeAll()` | `Unit` | Remove all event listeners |

### ChatEvent
Event enum constants.

| Enum Value | Trigger | Data Type |
|------------|---------|-----------|
| `SESSION_STARTED` | Local side joined RTC channel | null |
| `SESSION_ENDED` | Session end process completed | null |
| `USER_MESSAGE` | User speech result (streaming) | `ChannelMessage` |
| `ROBOT_MESSAGE` | Robot reply (streaming) | `ChannelMessage` |
| `AUDIO_MUTED` | Microphone muted | null |
| `AUDIO_UNMUTED` | Microphone unmuted | null |
| `ROBOT_JOINED` | Remote agent joined | null |
| `ROBOT_LEFT` | Remote agent left | null |
| `ERROR` | Error occurred | `ErrorMessage` |

#### ChannelMessage
- `text: String` – Message text
- `final: Boolean` – `true` = end of sentence, `false` = incremental
- `speakerId: String` – Speaker ID (assistant mode)
- `rawJson: String` – Raw JSON string

#### ErrorMessage
- `code: Int` – Error code
- `errMsg: String` – Error message

## Error Codes

| Code | Description |
|------|-------------|
| 3001 | Parameter validation failed (empty, invalid, missing fields) |
| 3002 | No available network |
| 3003 | Network request exception (interruption, non-2xx response) |
| 3004 | Microphone permission not granted |
| 3005 | Unsupported channel or platform |
| 3006 | Voice engine initialization failed |
| 3007 | Failed to join RTC channel |
| 3008 | Failed to leave RTC channel |
| 3009 | Interrupt called before connection is ready |
| 3010 | Command serialization failed |
| 3011 | Failed to send command / data stream |
| 3012 | SDK method called before engine initialization |
| 3013 | Failed to set microphone state |
| 3014 | Unknown underlying exception |
| 3015 | Connection interrupted during session start |
| 3016 | RTC data stream receive error |
| 3017 | Failed to create business data channel |
| 3018 | Remote agent join timeout |
| 3019 | Remote agent offline & reconnection timeout |
| 3020 | Business data JSON parsing failed |
| 3021 | Call flow conflict (duplicate start request) |

## Compatibility

| Item | Description |
|------|-------------|
| Android | minSdk 24 (Android 7.0+) |
| Language | Kotlin (dependencies bundled in AAR) |
| ABI | arm64-v8a, armeabi-v7a |
| Requirements | Microphone + network |

## Run Demo
The demo project includes Basic integration example.

Import into Android Studio, configure `robotKey` and `robotToken`, then run.
