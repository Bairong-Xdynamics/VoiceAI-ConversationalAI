#include <memory>
#include <string>

#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "protocol.h"
#include "rtc_protocol.h"

static const char* TAG = "app_main";

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
    protocol_->OnIncomingJson([](const cJSON* root) {
        // 收到 JSON 消息
    });
    protocol_->OnLogMessage([](const std::string& level, const std::string& msg,
                                const std::string& event, const std::string& desc) {
        // 日志透传
    });

    // 4. 标记启动
    protocol_->Start();

    // 5. 打开音频通道（需网络已就绪）
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