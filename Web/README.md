# Voice Call JS SDK

> A lightweight real-time intelligent voice conversation SDK based on WebRTC, enabling quick integration of high-quality voice AI interaction into web applications.

## Quick Start

### 1. Install

```sh
pnpm add @koi-video/voice-realtime-sdk
# or
npm install @koi-video/voice-realtime-sdk
```

### 2. Basic Usage

```javascript
import { ChatClient, VoiceEvents } from '@koi-video/voice-realtime-sdk';

// Initialize the client (obtain robotKey and robotToken from the platform first)
const client = new ChatClient(
  {
    robotKey: 'your_robot_key',      // from the platform
    robotToken: 'your_robot_token',  // from the platform
  },
  {
    userName: 'unique-user-id',      // unique user identifier
  }
);

// Register event listeners
client.on(VoiceEvents.SESSION_CREATED, ({ sessionId }) => {
  console.log('Session created', sessionId);
});

client.on(VoiceEvents.ROBOT_MESSAGE, ({ content }) => {
  console.log('Robot:', content);
});

client.on(VoiceEvents.ERROR, (err) => {
  console.error('Error:', err.code, err.message);
});

// Start voice conversation
try {
  const sessionId = await client.startVoiceChat();
  console.log('Voice chat started, session ID:', sessionId);
} catch (error) {
  console.error('Failed to start', error);
}
```

## Key Features

- 🎤 **Out-of-the-box** – Encapsulates WebRTC, audio capture/playback, connection management, and other low-level details
- 🔐 **Credential Authentication** – Secure access to the platform's AI agents using `robotKey` + `robotToken`
- 🎙️ **Real-time Voice Conversation** – Supports bidirectional streaming speech recognition and synthesis with low latency
- 🛑 **Interruption Support** – Interrupt the robot's response at any time for more natural conversations
- 🔇 **Audio Control** – Dynamic microphone muting/unmuting
- 📡 **Complete Event System** – Rich event notifications for session state, message flow, errors, and more
- 🌐 **Secure Context Required** – Requires HTTPS or localhost (browser microphone permission)

## Prerequisites

Before using this SDK, you need to:

1. Create an Agent (Robot) on the [Bairong Baigong Platform](https://alidocs.dingtalk.com/i/nodes/QBnd5ExVEanmejPpT29ZQ1R7VyeZqMmz)
2. Complete API publishing to obtain `robotKey` and `robotToken`
3. Ensure your application runs in a secure context (HTTPS or localhost)

> ⚠️ `robotKey` and `robotToken` are sensitive credentials. Keep them safe to avoid leaks and billing loss. In production, it's recommended to exchange for temporary credentials via your backend.

## Advanced Usage

### Full Event Listening

```javascript
import { ChatClient, VoiceEvents } from '@koi-video/voice-realtime-sdk';

const client = new ChatClient({ robotKey, robotToken }, { userName: 'user-123' });

// Session lifecycle
client.on(VoiceEvents.SESSION_CREATED, ({ sessionId }) => {});
client.on(VoiceEvents.SESSION_STARTED, ({ sessionId }) => {});
client.on(VoiceEvents.SESSION_ENDED, ({ sessionId, reason }) => {});

// Messages
client.on(VoiceEvents.USER_MESSAGE, ({ content, segmentId, raw }) => {
  // raw contains full transcription info: role, final, payload, etc.
});
client.on(VoiceEvents.ROBOT_MESSAGE, ({ content, segmentId, raw }) => {});

// Interruption
client.on(VoiceEvents.INTERRUPT, ({ sessionId }) => {});

// Audio mute state
client.on(VoiceEvents.AUDIO_MUTED, ({ sessionId }) => {});
client.on(VoiceEvents.AUDIO_UNMUTED, ({ sessionId }) => {});

// Catch-all events (debugging)
client.on(VoiceEvents.ALL, (eventName, data) => {
  console.log(`[${eventName}]`, data);
});
```

### Conversation Control

```javascript
// Interrupt the robot's current response
client.interrupt();

// Mute microphone (async)
await client.setAudioEnabled({ bool: false });

// Unmute microphone
await client.setAudioEnabled({ bool: true });

// End voice conversation
await client.stopVoiceChat();
```

### Complete Example (with auto-interrupt and auto-end)

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

// Register events
client.on(VoiceEvents.SESSION_CREATED, ({ sessionId }) => console.log('Session created', sessionId));
client.on(VoiceEvents.ROBOT_MESSAGE, ({ content }) => console.log('Robot:', content));
client.on(VoiceEvents.ERROR, (err) => console.error('Error:', err));

// Start conversation
const sessionId = await client.startVoiceChat();
console.log('Session ID:', sessionId);

// Interrupt after 5 seconds, end after 10 seconds
setTimeout(() => client.interrupt(), 5000);
setTimeout(() => client.stopVoiceChat(), 10000);
```

## API Reference

### ChatClient

The main client class for creating voice sessions, sending audio, and controlling the conversation flow.

#### Constructor

```typescript
new ChatClient(credentials: Credentials, options: ClientOptions)
```

- **Credentials**
  - `robotKey: string` – Agent key from the platform
  - `robotToken: string` – Agent token from the platform
- **ClientOptions**
  - `userName: string` – Unique user identifier (required; must be different for each user)

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `startVoiceChat()` | `Promise<string>` | Starts a voice conversation and returns the `sessionId` |
| `stopVoiceChat()` | `Promise<void>` | Ends the current voice conversation and releases resources |
| `interrupt()` | `void` | Interrupts the robot's ongoing response |
| `setAudioEnabled({ bool })` | `Promise<void>` | Mutes (`bool: false`) or unmutes (`bool: true`) the microphone |
| `on(event, handler)` | `void` | Registers an event listener |

### VoiceEvents

Event name constants – recommended over hardcoded strings.

| Constant | Value | Trigger |
|----------|-------|---------|
| `SESSION_CREATED` | `'SESSION_CREATED'` | HTTP start successful, session ready; payload `{ sessionId }` |
| `SESSION_STARTED` | `'SESSION_STARTED'` | Session officially starts (WebRTC connection established) |
| `SESSION_ENDED` | `'SESSION_ENDED'` | `stopVoiceChat()` called, RTC disconnection, or server‑side end; payload `{ sessionId, reason }` |
| `USER_MESSAGE` | `'USER_MESSAGE'` | User speech recognition result (streaming); payload `{ content, segmentId?, raw }` |
| `ROBOT_MESSAGE` | `'ROBOT_MESSAGE'` | Robot reply text (streaming); same payload |
| `INTERRUPT` | `'INTERRUPT'` | Conversation interrupted; payload `{ sessionId }` |
| `AUDIO_MUTED` | `'AUDIO_MUTED'` | Triggered after mute takes effect |
| `AUDIO_UNMUTED` | `'AUDIO_UNMUTED'` | Triggered after unmute takes effect |
| `ERROR` | `'ERROR'` | Error occurred; payload includes `code`, `message`, `sessionId?` |
| `ALL` | `'ALL'` | Catches all events; callback signature `(eventName, data)` |

> Example `raw` field structure:
> ```json
> {
>   "role": "user",        // "user" or "llm"
>   "final": false,        // false = incremental, true = final result
>   "text": "Hello",
>   "payload": { "emotion": "neutral" }
> }
> ```

## Browser Compatibility

- Modern browsers supporting WebRTC (Chrome, Firefox, Safari, Edge)
- **iOS Safari**: `startVoiceChat()` must be triggered by a user gesture (e.g., button click)
- Must run under **HTTPS** or **localhost** (browser security policy)

## Try Examples

### In Browser

```bash
cd demo
pnpm i
npm run demo
```

## Documentation