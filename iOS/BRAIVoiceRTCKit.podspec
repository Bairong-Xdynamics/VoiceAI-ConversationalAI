Pod::Spec.new do |s|
  s.name             = 'BRAIVoiceRTCKit'
  s.version          = '1.0.1'
  s.summary          = '百融智能语音 RTC SDK，封装业务鉴权与底层语音频道能力'
  s.homepage         = 'https://github.com/Bairong-Xdynamics/VoiceAI-ConversationalAI'
  s.license          = { :type => 'Proprietary' }
  s.author           = { 'VoiceAI Team' => 'voiceai@100credit.cn' }
  s.platform         = :ios, '13.0'
  # 二进制从 demo 仓库的 GitHub Release 页面拉取，zip 由 scripts/build_framework.sh 产出。
  # 底层 RTC 依赖已嵌套在 xcframework 内部，第三方无需感知。
  s.source           = {
    :http => 'https://github.com/Bairong-Xdynamics/VoiceAI-ConversationalAI/releases/download/v1.0.1/BR_AI_Voice_RTC_iOS_v1.0.1.zip'
  }
  s.vendored_frameworks = 'BRAIVoiceRTCKit.xcframework'

  s.frameworks = 'AVFoundation', 'CoreFoundation', 'SystemConfiguration', 'UIKit'
  s.libraries  = 'objc'
  s.requires_arc = true
end
