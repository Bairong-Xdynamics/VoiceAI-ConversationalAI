# RTC Voice Protocol Demo

A secondary-encapsulated voice RTC protocol component that provides voice channel creation, audio transmission/reception, and stream message transmission capabilities.

## Build / Flash / Monitor

```bash
idf.py set-target esp32s3
idf.py build flash monitor
```

## Library Usage

Place `components/protocols/` into your project's `components/` directory:

```
your_project/
├── main/
│   └── app_main.cpp
└── components/
    └── protocols/
        ├── include/
        │   ├── protocol.h          # Protocol base class interface
        │   └── rtc_protocol.h      # RtcProtocol implementation
        ├── libs/
        │   └── libbr_ai_voice_rtc.a  # Pre-compiled library
        └── CMakeLists.txt
```

### CMakeLists.txt

```cmake
set(COMPONENT_ADD_INCLUDEDIRS include)

register_component(INCLUDE_DIRS "." "include")

target_link_libraries(${COMPONENT_TARGET} INTERFACE "-L ${CMAKE_CURRENT_SOURCE_DIR}/libs")
target_link_libraries(${COMPONENT_TARGET} INTERFACE br_ai_voice_rtc)
```

### Quick Integration

```cpp
#include "protocol.h"
#include "rtc_protocol.h"

static std::unique_ptr<Protocol> protocol_;

extern "C" void app_main(void)
{
    // 1. Create instance
    protocol_ = std::make_unique<RtcProtocol>(
        "robot_key",    // Robot credential key
        "robot_token",  // Robot credential token
        "{}"            // Model configuration JSON
    );

    // 2. Set RTC voice server URL (required)
    protocol_->SetNetWorkUrl("https://your-server.com/api/realtime/webrtc/v1");

    // 3. Register callbacks (must be done before Start())
    protocol_->OnIncomingAudio([](std::unique_ptr<AudioStreamPacket> packet) {
        // Remote audio received → feed into decode/playback queue
    });
    protocol_->OnAudioChannelOpened([]() {
        // Audio channel opened
    });
    protocol_->OnAudioChannelClosed([]() {
        // Audio channel closed
    });
    protocol_->OnNetworkError([](const std::string& msg) {
        // Network error handling
    });
    protocol_->OnIncomingJson([](const std::string& msg) {
        // JSON message received
    });
    protocol_->OnLogMessage([](const std::string& level, const std::string& msg,
                                const std::string& event, const std::string& desc) {
        // Log passthrough
    });

    // 4. Mark as started
    protocol_->Start();

    // 5. Open audio channel (requires network to be ready)
    //    Internal flow: HTTP POST /start → get RTC parameters → join Agora channel
    protocol_->OpenAudioChannel();

    // 6. Send audio (20ms/frame, OPUS format)
    auto packet = std::make_unique<AudioStreamPacket>();
    packet->sample_rate = 16000;
    packet->frame_duration = 20;
    packet->payload.resize(640, 0);
    protocol_->SendAudio(std::move(packet));

    // 7. Close channel on teardown
    if (protocol_->IsAudioChannelOpened()) {
        protocol_->CloseAudioChannel();
    }
    protocol_.reset();
}
```

### API Quick Reference

| API | Description |
|------|------|
| `SetNetWorkUrl(url)` | Set RTC server address (required; otherwise OpenAudioChannel fails) |
| `UpdateConfig(key, token, config)` | Dynamically update credentials and model configuration |
| `Start()` | Mark as started (lightweight, no network operations) |
| `OpenAudioChannel()` | HTTP `/start` → get RTC parameters → join Agora channel |
| `CloseAudioChannel()` | Leave channel + HTTP `/stop` |
| `IsAudioChannelOpened()` | Check if channel is open |
| `SendAudio(packet)` | Send OPUS audio frame |

### Callback Reference

| Callback | Trigger |
|------|----------|
| `OnConnected()` | Protocol connection established |
| `OnDisconnected()` | Protocol connection disconnected |
| `OnAudioChannelOpened()` | Audio channel opened (joined channel successfully) |
| `OnAudioChannelClosed()` | Audio channel closed (left channel / disconnected) |
| `OnIncomingAudio(packet)` | Remote audio data received |
| `OnIncomingJson(root)` | JSON stream message received |
| `OnNetworkError(msg)` | Network / protocol error |
| `OnLogMessage(level, msg, event, desc)` | Internal log passthrough |

### Key Flow

```
SetNetWorkUrl → Start → OpenAudioChannel → OnAudioChannelOpened
                              ↓                   ↓
 
                         OnIncomingAudio       SendAudio 
                         OnIncomingJson           
                                                  ↓ 
                                            CloseAudioChannel → OnAudioChannelClosed
```