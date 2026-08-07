# rtc语音协议demo

二次封装的语音 RTC 协议组件，提供语音通道的创建、音频收发、流消息传输等能力。

## 编译 / 烧录 / 日志监控

```bash
idf.py set-target esp32s3
idf.py build flash monitor
```

## 库使用方法

将 `components/protocols/` 放入项目 `components/` 目录：

```
your_project/
├── main/
│   └── app_main.cpp
└── components/
    └── protocols/
        ├── include/
        │   ├── protocol.h          # Protocol 基类接口
        │   └── rtc_protocol.h      # RtcProtocol 实现
        ├── libs/
        │   └── libbr_ai_voice_rtc.a  # 预编译库
        └── CMakeLists.txt
```

### CMakeLists.txt

```cmake
set(COMPONENT_ADD_INCLUDEDIRS include)

register_component(INCLUDE_DIRS "." "include")

target_link_libraries(${COMPONENT_TARGET} INTERFACE "-L ${CMAKE_CURRENT_SOURCE_DIR}/libs")
target_link_libraries(${COMPONENT_TARGET} INTERFACE br_ai_voice_rtc)
```

### 快速集成

```cpp
#include "protocol.h"
#include "rtc_protocol.h"

static std::unique_ptr<Protocol> protocol_;

extern "C" void app_main(void)
{
    // 1. 创建实例
    protocol_ = std::make_unique<RtcProtocol>(
        "robot_key",    // 机器人凭证 key
        "robot_token",  // 机器人凭证 token
        "{}"            // 模型配置 JSON
    );

    // 2. 设置 RTC 语音服务器 URL（必调）
    protocol_->SetNetWorkUrl("https://your-server.com/api/realtime/webrtc/v1");

    // 3. 注册回调（必须在 Start() 之前）
    protocol_->OnIncomingAudio([](std::unique_ptr<AudioStreamPacket> packet) {
        // 收到远端音频 → 送入解码播放队列
    });
    protocol_->OnAudioChannelOpened([]() {
        // 音频通道打开
    });
    protocol_->OnAudioChannelClosed([]() {
        // 音频通道关闭
    });
    protocol_->OnNetworkError([](const std::string& msg) {
        // 网络错误处理
    });
    protocol_->OnIncomingJson([](const std::string& msg) {
        // 收到 JSON 消息
    });
    protocol_->OnLogMessage([](const std::string& level, const std::string& msg,
                                const std::string& event, const std::string& desc) {
        // 日志透传
    });

    // 4. 标记启动
    protocol_->Start();

    // 5. 打开音频通道（需网络已就绪）
    //    内部流程：HTTP POST /start → 获取 RTC 参数 → 加入 Agora 频道
    protocol_->OpenAudioChannel();

    // 6. 发送音频（20ms/帧，OPUS 格式）
    auto packet = std::make_unique<AudioStreamPacket>();
    packet->sample_rate = 16000;
    packet->frame_duration = 20;
    packet->payload.resize(640, 0);
    protocol_->SendAudio(std::move(packet));

    // 7. 销毁时关闭通道
    if (protocol_->IsAudioChannelOpened()) {
        protocol_->CloseAudioChannel();
    }
    protocol_.reset();
}
```

### API 速查

| 接口 | 说明 |
|------|------|
| `SetNetWorkUrl(url)` | 设置 RTC 服务器地址（必调，否则 OpenAudioChannel 失败） |
| `UpdateConfig(key, token, config)` | 动态更新凭证和模型配置 |
| `Start()` | 标记启动（轻量，无网络操作） |
| `OpenAudioChannel()` | HTTP `/start` → 获取 RTC 参数 → 加入 Agora 频道 |
| `CloseAudioChannel()` | 离开频道 + HTTP `/stop` |
| `IsAudioChannelOpened()` | 查询通道是否打开 |
| `SendAudio(packet)` | 发送 OPUS 音频帧 |

### 回调一览

| 回调 | 触发时机 |
|------|----------|
| `OnConnected()` | 协议连接建立 |
| `OnDisconnected()` | 协议连接断开 |
| `OnAudioChannelOpened()` | 音频通道打开（加入频道成功） |
| `OnAudioChannelClosed()` | 音频通道关闭（离开频道/断线） |
| `OnIncomingAudio(packet)` | 收到远端音频数据 |
| `OnIncomingJson(root)` | 收到 JSON 流消息 |
| `OnNetworkError(msg)` | 网络/协议错误 |
| `OnLogMessage(level, msg, event, desc)` | 内部日志透传 |

### 关键流程

```
SetNetWorkUrl → Start → OpenAudioChannel → OnAudioChannelOpened
                              ↓                   ↓
 
                         OnIncomingAudio       SendAudio 
                         OnIncomingJson           
                                                  ↓ 
                                            CloseAudioChannel → OnAudioChannelClosed
```