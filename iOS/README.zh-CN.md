# 百语智能语音通话 iOS SDK

> 轻量级实时智能语音对话开发工具包，基于 WebRTC 技术，为 iOS 应用快速集成高质量智能语音交互能力。

## 产品概述
百语智能语音通话 iOS SDK 封装了服务端连接、音频采集播放、对话控制等底层复杂逻辑，帮助开发者仅需 10 分钟即可为 iOS 应用接入端到端的实时语音对话能力。
SDK 深度对接百语平台智能体机器人，适用于智能客服、语音助手、智能外呼等多种业务场景。

## 主要特性
- 🎤 **开箱即用**：封装 WebRTC、音频采集与播放、连接管理等底层细节
- 🔐 **凭证认证**：使用 robotKey + robotToken 安全接入百语平台智能体
- 🎙️ **实时语音对话**：双向流式语音识别与合成，低延迟自然交互
- 🛑 **打断支持**：可随时打断机器人回复，对话流程更自然
- 🔇 **音频控制**：支持动态静音 / 取消静音麦克风
- 📡 **完整回调体系**：提供会话状态、消息流转、错误等丰富代理回调
- 📱 **原生适配**：支持 iOS 13.0 及以上系统，arm64 真机架构

## 接入前提
使用本 SDK 前，您需要：

1. 在 [百融百语平台](https://alidocs.dingtalk.com/i/nodes/QBnd5ExVEanmejPpT29ZQ1R7VyeZqMmz) 创建智能体 Agent（Robot）
2. 通过 API 方式发布智能体，获取 `robotKey` 和 `robotToken`
3. 应用目标系统版本不低于 iOS 13.0，仅支持真机运行

> ⚠️ `robotKey` 和 `robotToken` 为敏感凭证，请妥善保管，避免泄露造成计费损失。生产环境建议通过服务端换取临时凭证，严禁在客户端硬编码。

## 快速开始

### 1. 导入 SDK 到项目
1. 下载并解压正式环境 SDK 包，获取 `BRAIVoiceRTCKit.framework`
2. 打开 Xcode 工程，右键点击工程名称，选择 **Add Files to "工程名"…**
3. 选中 `BRAIVoiceRTCKit.framework`，勾选 **Copy items if needed**，并在 Add to targets 中选择目标 Target，点击 Add 完成导入

### 2. 配置 Framework 依赖
1. 在 Xcode 中选中项目 Target，切换到 **General** 标签页
2. 找到 **Frameworks, Libraries, and Embedded Content** 区域
3. 将 `BRAIVoiceRTCKit.framework` 的嵌入方式设置为 **Embed & Sign**

### 3. 配置系统权限
SDK 需要麦克风权限进行音频采集，需在工程 `Info.plist` 中添加权限声明：
- 右键点击 Info.plist，选择 **Add Row**
- 键名选择 `Privacy - Microphone Usage Description`
- 值填写权限申请理由（例如："需要使用麦克风与智能体进行语音交互"）

### 4. 基本用法

```objc
#import <BRAIVoiceRTCKit/BRAIVoiceRTCKit.h>

@interface YourViewController () <BRAIVoiceRTCManagerDelegate>
@property (nonatomic, strong) BRAIVoiceRTCManager *rtcManager;
@end

@implementation YourViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化语音交互管理器
    self.rtcManager = [[BRAIVoiceRTCManager alloc] initAIVoiceRTCWithKey:@"your_robot_key"
                                                                  token:@"your_robot_token"
                                                               userName:@"unique-user-id"];
    self.rtcManager.delegate = self;
}

// 启动语音对话
- (void)startVoiceChat {
    [self.rtcManager startVoiceChatCompleteCallBack:^(BOOL isSuccess, BRAIVoiceRTCError * _Nullable error) {
        if (isSuccess) {
            NSLog(@"语音交互启动成功");
        } else {
            NSLog(@"启动失败：%@", error.errorMessage);
        }
    }];
}

// 结束语音对话
- (void)stopVoiceChat {
    [self.rtcManager stopVoiceChatCompleteCallBack:^(BOOL isSuccess, BRAIVoiceRTCError * _Nullable error) {
        if (isSuccess) {
            NSLog(@"语音交互停止成功");
        } else {
            NSLog(@"停止失败：%@", error.errorMessage);
        }
    }];
}

#pragma mark - BRAIVoiceRTCManagerDelegate
// 接收流消息
- (void)onVoiceRTCReceiveStreamMessage:(NSString *)text fromRole:(BRAIVoiceRTCStreamMessageRole)fromRole raw:(NSString *)raw {
    if (fromRole == BRAIVoiceRTCStreamMessageRoleRobot) {
        NSLog(@"机器人: %@", text);
    }
}

// 运行时错误
- (void)onVoiceRTCRuntimeError:(BRAIVoiceRTCError *)error {
    NSLog(@"错误: %ld - %@", (long)error.errorCode, error.errorMessage);
}

@end
```

## 高级用法

### 完整代理回调

```objc
#pragma mark - BRAIVoiceRTCManagerDelegate

// 打断结果回调
- (void)onVoiceRTCInterruptResult:(BOOL)isSuccess error:(BRAIVoiceRTCError *)error {
    if (isSuccess) {
        NSLog(@"打断成功");
    } else {
        NSLog(@"打断失败: %@", error.errorMessage);
    }
}

// 麦克风开关结果回调
- (void)onVoiceRTCSetAudioEnableResult:(BOOL)isSuccess enable:(BOOL)enable error:(BRAIVoiceRTCError *)error {
    NSLog(@"麦克风%@: %@", enable ? @"开启" : @"关闭", isSuccess ? @"成功" : error.errorMessage);
}

// 运行时异常回调
- (void)onVoiceRTCRuntimeError:(BRAIVoiceRTCError *)error {
    // 处理未被其他回调覆盖的底层异常
}

// RTC 数据流业务回调
- (void)onVoiceRTCReceiveStreamMessage:(NSString *)text fromRole:(BRAIVoiceRTCStreamMessageRole)fromRole raw:(NSString *)raw {
    // fromRole: User / Robot / Unknown
    // raw 为原始 JSON 字符串，可自定义解析
}

// 远端用户上线回调
- (void)onVoiceRTCRemoteUserDidJoinChannelWithUid:(NSUInteger)uid elapsed:(NSInteger)elapsed {
    NSLog(@"远端用户加入，uid: %lu，耗时: %ldms", (unsigned long)uid, (long)elapsed);
}

// 远端用户下线回调
- (void)onVoiceRTCRemoteUserDidLeaveChannelWithUid:(NSUInteger)uid offlineReason:(NSInteger)offlineReason {
    // offlineReason: 0=主动离开 1=超时掉线 2=角色切换
}
```

### 对话控制

```objc
// 打断机器人当前回复
[self.rtcManager interrupt];

// 静音麦克风
[self.rtcManager setAudioEnable:NO];

// 取消静音
[self.rtcManager setAudioEnable:YES];

// 获取 SDK 版本号
NSString *version = [BRAIVoiceRTCManager sdkVersion];
```

### 完整示例（自动打断 + 结束）

```objc
#import <BRAIVoiceRTCKit/BRAIVoiceRTCKit.h>

@interface DemoViewController () <BRAIVoiceRTCManagerDelegate>
@property (nonatomic, strong) BRAIVoiceRTCManager *rtcManager;
@end

@implementation DemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.rtcManager = [[BRAIVoiceRTCManager alloc] initAIVoiceRTCWithKey:YOUR_ROBOT_KEY
                                                                  token:YOUR_ROBOT_TOKEN
                                                               userName:@"demo-user-1"];
    self.rtcManager.delegate = self;
    
    // 启动对话
    [self.rtcManager startVoiceChatCompleteCallBack:^(BOOL isSuccess, BRAIVoiceRTCError * _Nullable error) {
        if (!isSuccess) {
            NSLog(@"启动失败: %@", error.errorMessage);
            return;
        }
        
        // 5秒后打断
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.rtcManager interrupt];
        });
        
        // 10秒后结束
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.rtcManager stopVoiceChatCompleteCallBack:^(BOOL isSuccess, BRAIVoiceRTCError * _Nullable error) {
                NSLog(@"会话结束: %@", isSuccess ? @"成功" : error.errorMessage);
            }];
        });
    }];
}

@end
```

## API 参考

### BRAIVoiceRTCManager
语音交互核心管理类，负责会话创建、语音控制与事件分发。

#### 初始化方法

```objc
- (instancetype)initAIVoiceRTCWithKey:(NSString *)robotKey
                                token:(NSString *)robotToken
                             userName:(NSString *)userName;
```

**参数说明**
- `robotKey: NSString` – 百语平台智能体 Key
- `robotToken: NSString` – 百语平台智能体 Token
- `userName: NSString` – 唯一用户标识（必填，不同用户必须不同）

#### 方法

| 方法名 | 返回值 | 描述 |
|--------|--------|------|
| `startVoiceChatCompleteCallBack:` | `void` | 启动语音对话，建立 RTC 连接，结果通过 block 回调 |
| `stopVoiceChatCompleteCallBack:` | `void` | 结束语音对话，释放所有资源，结果通过 block 回调 |
| `interrupt` | `void` | 打断机器人回复，结果通过代理回调 |
| `setAudioEnable:` | `void` | 开启 / 关闭麦克风采集，结果通过代理回调 |
| `sdkVersion` (类方法) | `NSString` | 获取当前 SDK 版本号 |

### BRAIVoiceRTCManagerDelegate
代理协议，用于接收 SDK 所有事件回调。

| 代理方法 | 触发时机 | 核心参数 |
|----------|----------|----------|
| `onVoiceRTCInterruptResult:error:` | 调用 `interrupt` 后返回结果 | `isSuccess` 是否成功，`error` 错误信息 |
| `onVoiceRTCSetAudioEnableResult:enable:error:` | 调用 `setAudioEnable:` 后返回结果 | `enable` 目标状态，`isSuccess` 是否成功 |
| `onVoiceRTCRuntimeError:` | 发生未被其他回调覆盖的运行时异常 | `error` 错误对象 |
| `onVoiceRTCReceiveStreamMessage:fromRole:raw:` | 收到 RTC 业务数据流 | `text` 解析文本，`fromRole` 发送方角色，`raw` 原始JSON |
| `onVoiceRTCRemoteUserDidJoinChannelWithUid:elapsed:` | 远端智能体加入频道 | `uid` 用户标识，`elapsed` 加入耗时(ms) |
| `onVoiceRTCRemoteUserDidLeaveChannelWithUid:offlineReason:` | 远端智能体离开频道 | `uid` 用户标识，`offlineReason` 下线原因 |

#### 数据结构说明
**BRAIVoiceRTCError**
- `errorCode: NSInteger` – 错误码
- `errorMessage: NSString` – 错误描述

**BRAIVoiceRTCStreamMessageRole 枚举**
- `BRAIVoiceRTCStreamMessageRoleUser` – 用户侧消息
- `BRAIVoiceRTCStreamMessageRoleRobot` – 机器人侧消息
- `BRAIVoiceRTCStreamMessageRoleUnknown` – 未知角色

## 错误码说明

| 错误码 | 详细描述 |
|--------|----------|
| 3001 | 参数校验错误（入参为空、格式非法或缺失必要字段） |
| 3002 | 当前设备无可用网络连接 |
| 3003 | SDK 内部网络请求异常（网络中断、服务端返回非 2xx） |
| 3004 | 应用未获取麦克风权限 |
| 3005 | 不支持的渠道或运行平台 |
| 3006 | 语音引擎初始化异常 |
| 3007 | 本端加入 RTC 频道异常 |
| 3008 | 本端离开 RTC 频道异常 |
| 3009 | 调用打断方法时，语音会话尚未建立 |
| 3010 | 业务指令序列化失败 |
| 3011 | 发送指令或业务数据流失败 |
| 3012 | 语音引擎未初始化时调用 SDK 方法 |
| 3013 | 麦克风开关状态设置失败 |
| 3014 | 底层未知系统异常 |
| 3015 | 发起会话过程中连接异常中断 |
| 3016 | 底层接收 RTC 数据流异常 |
| 3017 | 创建业务数据流通道失败 |
| 3018 | 本端进房后远端智能体上线超时 |
| 3019 | 远端智能体下线且重连超时 |
| 3020 | 业务数据流 JSON 解析失败 |
| 3021 | 调用流程互斥（重复发起未完成的启动请求） |

## 兼容性说明

| 兼容项 | 具体要求 |
|--------|----------|
| 系统版本 | iOS 13.0 及以上 |
| 设备架构 | 仅支持真机 arm64 架构，不支持模拟器 |
| 编译选项 | 不支持 BitCode |
| 运行要求 | 设备具备麦克风与网络连接 |

## 运行示例
- 正式环境 SDK Demo 项目源码
- 导入 Xcode 后配置 `robotKey` 与 `robotToken`，连接真机即可运行

