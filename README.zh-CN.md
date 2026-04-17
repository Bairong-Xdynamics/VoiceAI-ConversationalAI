# VoiceAI-ConversationalAI

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> One‑stop intelligent voice conversation solution – lightweight real‑time voice interaction SDKs for Web, Android, and iOS, enabling quick integration of AI agent voice capabilities.

## Features

- 🎤 **Cross‑platform** – SDKs for Web (JavaScript/TypeScript), Android (Kotlin/Java), and iOS (Swift)
- 🔐 **Secure Authentication** – Platform key/token auth with support for dynamic temporary credentials in production
- 🎙️ **Real‑time Voice Conversation** – Low‑latency bidirectional speech recognition and synthesis via WebRTC
- 🛑 **Interruption Support** – Interrupt the robot’s reply at any time for natural conversations
- 🔇 **Audio Control** – Dynamic microphone muting/unmuting
- 📡 **Rich Event System** – Session lifecycle, message streaming, errors, and more
- 📦 **Out‑of‑the‑box** – Encapsulates WebRTC, audio capture/playback, and connection management


## SDK Overview per Platform

| Platform | Language | Core Class | Status |
|----------|----------|------------|--------|
| Web | JavaScript / TypeScript | `ChatClient` | ✅ Available |
| Android | Kotlin / Java | `VoiceChatClient` | 🚧 In development |
| iOS | Swift | `VoiceChatClient` | 🚧 In development |

> See each subdirectory’s README for detailed API docs and usage examples.

## Common Prerequisites

1. Create an Agent on your voice AI platform (Bairong Baigong) and obtain `robotKey` + `robotToken`
2. Ensure the client runs in a secure environment:
   - Web: HTTPS or localhost
   - Android / iOS: normal network permissions
3. Handle microphone permission requests (user consent)


## License

MIT © VoiceAI Team

