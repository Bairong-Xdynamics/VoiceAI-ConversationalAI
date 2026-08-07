#ifndef PROTOCOL_H
#define PROTOCOL_H

#include <cJSON.h>
#include <string>
#include <functional>
#include <chrono>
#include <vector>

struct AudioStreamPacket {
    int sample_rate = 0;
    int frame_duration = 0;
    uint32_t timestamp = 0;
    std::vector<uint8_t> payload;
};

class Protocol {
public:
    virtual ~Protocol() = default;

    void OnIncomingAudio(std::function<void(std::unique_ptr<AudioStreamPacket> packet)> callback);
    void OnIncomingJson(std::function<void(const cJSON* root)> callback);
    void OnAudioChannelOpened(std::function<void()> callback);
    void OnAudioChannelClosed(std::function<void()> callback);
    void OnNetworkError(std::function<void(const std::string& message)> callback);
    void OnLogMessage(std::function<void(const std::string& level, const std::string& message,
        const std::string& event, const std::string& desc)> callback);

    std::string GetVersion() const;
    virtual void UpdateConfig(const std::string& robot_key, const std::string& robot_token, const std::string& model_config) = 0;
    virtual void SetNetWorkUrl(const std::string& config_url) = 0;
    virtual bool Start() = 0;
    virtual bool OpenAudioChannel() = 0;
    virtual void CloseAudioChannel() = 0;
    virtual bool IsAudioChannelOpened() const = 0;
    virtual bool SendAudio(std::unique_ptr<AudioStreamPacket> packet) = 0;
    virtual bool SendText(const std::string& text) = 0;

protected:
    std::function<void(const cJSON* root)> on_incoming_json_;
    std::function<void(std::unique_ptr<AudioStreamPacket> packet)> on_incoming_audio_;
    std::function<void()> on_audio_channel_opened_;
    std::function<void()> on_audio_channel_closed_;
    std::function<void(const std::string& message)> on_network_error_;
    std::function<void()> on_connected_;
    std::function<void()> on_disconnected_;
    std::function<void(const std::string& level, const std::string& event_desc, const std::string& module, const std::string& detail)> on_log_message_;

    bool error_occurred_ = false;
    std::chrono::time_point<std::chrono::steady_clock> last_incoming_time_;

    virtual void SetError(const std::string& message);
    virtual bool IsTimeout() const;
};

#endif // PROTOCOL_H

