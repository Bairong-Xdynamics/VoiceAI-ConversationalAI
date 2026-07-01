//
//  ViewController.m
//  BRAIVoiceRTCDemo
//
//  Created by admin on 2026/4/21.
//

#import "ViewController.h"
#import "DemoCredentialDefaultsKeys.h"
#import "DemoCredentialConfigViewController.h"
#import <BRAIVoiceRTCKit/BRAIVoiceRTCKit.h>

@interface ViewController () <BRAIVoiceRTCManagerDelegate>

@property (nonatomic, strong, nullable) BRAIVoiceRTCManager *rtcManager;
@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) UIButton *stopButton;
@property (nonatomic, strong) UIButton *interruptButton;
@property (nonatomic, strong) UIButton *muteButton;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, assign) BOOL isAudioEnabled;
@property (nonatomic, copy, nullable) NSString *demoRtcCredentialFingerprint;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"BRAIVoiceRTCDemo";
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.isAudioEnabled = YES;

    [self setupNavigationItems];
    [self setupViews];

    [self appendDisplayLine:@"调试页已初始化。"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self demo_updateRtcManagerForCurrentCredentials];
}

#pragma mark - UI

- (void)setupNavigationItems {
    UIBarButtonItem *configItem = [[UIBarButtonItem alloc] initWithTitle:@"配置"
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(openCredentialConfigAction)];
    UIBarButtonItem *clearItem = [[UIBarButtonItem alloc] initWithTitle:@"清空"
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(clearTextAction)];
    self.navigationItem.leftBarButtonItem = configItem;
    self.navigationItem.rightBarButtonItem = clearItem;
}

- (void)setupViews {
    self.startButton = [self makeActionButtonWithTitle:@"发起语音交互" action:@selector(startVoiceChatAction)];
    self.stopButton = [self makeActionButtonWithTitle:@"停止语音交互" action:@selector(stopVoiceChatAction)];
    self.interruptButton = [self makeActionButtonWithTitle:@"打断" action:@selector(interruptAction)];
    self.muteButton = [self makeActionButtonWithTitle:@"静音" action:@selector(toggleMuteAction)];

    UIStackView *firstRow = [[UIStackView alloc] initWithArrangedSubviews:@[self.startButton, self.stopButton]];
    firstRow.axis = UILayoutConstraintAxisHorizontal;
    firstRow.alignment = UIStackViewAlignmentFill;
    firstRow.distribution = UIStackViewDistributionFillEqually;
    firstRow.spacing = 12.0;
    firstRow.translatesAutoresizingMaskIntoConstraints = NO;

    UIStackView *secondRow = [[UIStackView alloc] initWithArrangedSubviews:@[self.interruptButton, self.muteButton]];
    secondRow.axis = UILayoutConstraintAxisHorizontal;
    secondRow.alignment = UIStackViewAlignmentFill;
    secondRow.distribution = UIStackViewDistributionFillEqually;
    secondRow.spacing = 12.0;
    secondRow.translatesAutoresizingMaskIntoConstraints = NO;

    self.textView = [[UITextView alloc] init];
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    self.textView.editable = NO;
    self.textView.selectable = YES;
    self.textView.alwaysBounceVertical = YES;
    self.textView.font = [UIFont systemFontOfSize:15.0];
    self.textView.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.textView.textColor = [UIColor labelColor];
    self.textView.layer.cornerRadius = 12.0;
    self.textView.layer.masksToBounds = YES;

    [self.view addSubview:firstRow];
    [self.view addSubview:secondRow];
    [self.view addSubview:self.textView];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [firstRow.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:16.0],
        [firstRow.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor constant:16.0],
        [firstRow.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-16.0],
        [firstRow.heightAnchor constraintEqualToConstant:44.0],

        [secondRow.topAnchor constraintEqualToAnchor:firstRow.bottomAnchor constant:12.0],
        [secondRow.leadingAnchor constraintEqualToAnchor:firstRow.leadingAnchor],
        [secondRow.trailingAnchor constraintEqualToAnchor:firstRow.trailingAnchor],
        [secondRow.heightAnchor constraintEqualToConstant:44.0],

        [self.textView.topAnchor constraintEqualToAnchor:secondRow.bottomAnchor constant:16.0],
        [self.textView.leadingAnchor constraintEqualToAnchor:firstRow.leadingAnchor],
        [self.textView.trailingAnchor constraintEqualToAnchor:firstRow.trailingAnchor],
        [self.textView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:-16.0]
    ]];
}

- (UIButton *)makeActionButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
    button.backgroundColor = [UIColor systemBlueColor];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.layer.cornerRadius = 10.0;
    button.layer.masksToBounds = YES;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

#pragma mark - Credentials & RTC 初始化

- (NSString *)demo_trimCredentialText:(NSString *)text {
    return [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
}

- (BOOL)demo_hasCompleteCredentialsInUserDefaults {
    return [self demo_credentialFingerprintFromUserDefaults].length > 0;
}

/// 三项均已非空时返回稳定指纹；否则返回 nil。
- (NSString *)demo_credentialFingerprintFromUserDefaults {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *robotKey = [self demo_trimCredentialText:[ud stringForKey:kDemoCredentialUDRobotKey]];
    NSString *robotToken = [self demo_trimCredentialText:[ud stringForKey:kDemoCredentialUDRobotToken]];
    NSString *userName = [self demo_trimCredentialText:[ud stringForKey:kDemoCredentialUDUserName]];
    if (robotKey.length == 0 || robotToken.length == 0 || userName.length == 0) {
        return nil;
    }
    return [NSString stringWithFormat:@"%@|%@|%@", robotKey, robotToken, userName];
}

- (void)demo_refreshRtcManagerFromUserDefaults {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *robotKey = [self demo_trimCredentialText:[ud stringForKey:kDemoCredentialUDRobotKey]];
    NSString *robotToken = [self demo_trimCredentialText:[ud stringForKey:kDemoCredentialUDRobotToken]];
    NSString *userName = [self demo_trimCredentialText:[ud stringForKey:kDemoCredentialUDUserName]];
    self.rtcManager = [[BRAIVoiceRTCManager alloc] initAIVoiceRTCWithKey:robotKey
                                                                  token:robotToken
                                                               userName:userName];
    self.rtcManager.delegate = self;
}

- (void)demo_presentCredentialGuideIfNeeded {
    if (self.presentedViewController != nil) {
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"尚未配置凭证"
                                                                   message:@"请轻点左上角「配置」进入配置页，填写 robotKey、robotToken、userName 后返回本页。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)demo_updateRtcManagerForCurrentCredentials {
    NSString *fingerprint = [self demo_credentialFingerprintFromUserDefaults];
    if (fingerprint == nil) {
        self.rtcManager = nil;
        self.demoRtcCredentialFingerprint = nil;
        [self demo_presentCredentialGuideIfNeeded];
        return;
    }
    if (self.rtcManager != nil && [fingerprint isEqualToString:self.demoRtcCredentialFingerprint]) {
        return;
    }
    [self demo_refreshRtcManagerFromUserDefaults];
    self.demoRtcCredentialFingerprint = fingerprint;
}

- (void)openCredentialConfigAction {
    DemoCredentialConfigViewController *vc = [[DemoCredentialConfigViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Actions

- (void)startVoiceChatAction {
    [self.view endEditing:YES];
    if (![self demo_hasCompleteCredentialsInUserDefaults]) {
        [self demo_updateRtcManagerForCurrentCredentials];
        [self appendDisplayLine:@"发起失败：请先完成配置。"];
        return;
    }
    [self demo_updateRtcManagerForCurrentCredentials];
    if (self.rtcManager == nil) {
        [self appendDisplayLine:@"发起失败：未能初始化 RTC。"];
        return;
    }

    [self appendDisplayLine:@"点击发起语音交互。"];
    __weak typeof(self) weakSelf = self;
    [self.rtcManager startVoiceChatCompleteCallBack:^(BOOL isSuccess, BRAIVoiceRTCError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }

        if (isSuccess) {
            [strongSelf appendDisplayLine:@"发起语音交互成功。"];
        } else {
            [strongSelf appendDisplayLine:[NSString stringWithFormat:@"发起语音交互失败：%@", error.errorMessage ?: @"未知错误"]];
        }
    }];
}

- (void)stopVoiceChatAction {
    if (self.rtcManager == nil) {
        [self appendDisplayLine:@"停止语音交互：未初始化（请先配置凭证）。"];
        return;
    }
    [self appendDisplayLine:@"点击停止语音交互。"];
    __weak typeof(self) weakSelf = self;
    [self.rtcManager stopVoiceChatCompleteCallBack:^(BOOL isSuccess, BRAIVoiceRTCError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }

        if (isSuccess) {
            [strongSelf appendDisplayLine:@"停止语音交互成功。"];
        } else {
            [strongSelf appendDisplayLine:[NSString stringWithFormat:@"停止语音交互失败：%@", error.errorMessage ?: @"未知错误"]];
        }
    }];
    
}

- (void)interruptAction {
    if (self.rtcManager == nil) {
        [self appendDisplayLine:@"打断：未初始化（请先配置凭证）。"];
        return;
    }
    [self appendDisplayLine:@"点击打断。"];
    [self.rtcManager interrupt];
}

- (void)toggleMuteAction {
    if (self.rtcManager == nil) {
        [self appendDisplayLine:@"麦克风：未初始化（请先配置凭证）。"];
        return;
    }
    self.isAudioEnabled = !self.isAudioEnabled;
    [self.muteButton setTitle:(self.isAudioEnabled ? @"静音" : @"取消静音") forState:UIControlStateNormal];
    [self appendDisplayLine:(self.isAudioEnabled ? @"恢复本地音频。": @"静音本地音频。")];
    [self.rtcManager setAudioEnable:self.isAudioEnabled];
}


- (void)clearTextAction {
    self.textView.text = @"";
}

#pragma mark - BRAIVoiceRTCManagerDelegate

/**
 * 运行期错误（不含打断/麦克风结果，二者见 `onVoiceRTCInterruptResult:error:` 与 `onVoiceRTCSetAudioEnableResult:enable:error:`）。
 */
- (void)onVoiceRTCRuntimeError:(BRAIVoiceRTCError *)error {
    NSString *msg = error.errorMessage.length > 0 ? error.errorMessage : @"(无描述)";
    [self appendDisplayLine:[NSString stringWithFormat:@"运行期错误 (code=%lu)：%@", (unsigned long)error.errorCode, msg]];
}

- (void)onVoiceRTCInterruptResult:(BOOL)isSuccess error:(BRAIVoiceRTCError *)error {
    if (isSuccess) {
        [self appendDisplayLine:@"打断：成功"];
    } else {
        NSString *msg = error.errorMessage.length > 0 ? error.errorMessage : @"未知错误";
        [self appendDisplayLine:[NSString stringWithFormat:@"打断：失败 — %@", msg]];
    }
}

- (void)onVoiceRTCSetAudioEnableResult:(BOOL)isSuccess enable:(BOOL)enable error:(BRAIVoiceRTCError *)error {
    NSString *target = enable ? @"开" : @"关";
    if (isSuccess) {
        [self appendDisplayLine:[NSString stringWithFormat:@"麦克风开关（目标：%@）：成功", target]];
    } else {
        NSString *msg = error.errorMessage.length > 0 ? error.errorMessage : @"未知错误";
        [self appendDisplayLine:[NSString stringWithFormat:@"麦克风开关（目标：%@）：失败 — %@", target, msg]];
    }
}

/**
 * 收到数据流业务回调：`text` 为 JSON 中 `text` 字段，`raw` 为整条 JSON 字符串（`\u` 已解码为 UTF-8 可见字符）。
 *
 * @param text     转写/模型文本内容。
 * @param fromRole 由 JSON 中 `role` 推导：user → User，llm → Robot。
 * @param raw      完整数据流 JSON 文本（UTF-8 语义字符串）。
 */
- (void)onVoiceRTCReceiveStreamMessage:(NSString *)text
                              fromRole:(BRAIVoiceRTCStreamMessageRole)fromRole
                                   raw:(NSString *)raw {
    NSString *roleLabel = [self demo_labelForStreamMessageRole:fromRole];
    //[self appendDisplayLine:[NSString stringWithFormat:@"收到原始消息 role=%@\n text：%@\n raw：%@",
//                             roleLabel,
//                             text.length > 0 ? text : @"(空)",
//                             raw.length > 0 ? raw : @"(空)"]];
    [self appendDisplayLine:[NSString stringWithFormat:@"收到原始消息 role=%@\n text：%@\n",
                             roleLabel,
                             text.length > 0 ? text : @"(空)"]];
    NSData *rawData = [raw dataUsingEncoding:NSUTF8StringEncoding];
    if (rawData.length == 0) {
        return;
    }
    NSError *err = nil;
    id obj = [NSJSONSerialization JSONObjectWithData:rawData options:0 error:&err];
    NSDictionary *root = [obj isKindOfClass:[NSDictionary class]] ? obj : nil;
    if (root != nil) {
        [self demo_appendTranscriptionSummaryIfAnyForStreamRoot:root];
    }
}

#pragma mark - Demo stream JSON (业务层解析示例)

- (NSString *)demo_labelForStreamMessageRole:(BRAIVoiceRTCStreamMessageRole)role {
    switch (role) {
        case BRAIVoiceRTCStreamMessageRoleUser:
            return @"User(ASR)";
        case BRAIVoiceRTCStreamMessageRoleRobot:
            return @"Robot(LLM)";
        case BRAIVoiceRTCStreamMessageRoleUnknown:
            return @"Unknown";
    }
}

- (void)demo_appendTranscriptionSummaryIfAnyForStreamRoot:(NSDictionary *)root {
    NSDictionary *leaf = [self demo_nestedTranscriptionPayloadIfAny:root];
    if (leaf == nil) {
        return;
    }
    NSString *role = [self demo_stringForCaseInsensitiveKey:@"role" inDictionary:leaf];
    NSString *text = [self demo_stringForCaseInsensitiveKey:@"text" inDictionary:leaf];
    NSString *prefix = [self demo_transcriptPrefixForRole:role];
    [self appendDisplayLine:[NSString stringWithFormat:@"[Demo 转写解析] %@：%@", prefix, text ?: @""]];
}

- (NSString *)demo_transcriptPrefixForRole:(NSString *)role {
    NSString *normalized = [[role stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
    if ([normalized isEqualToString:@"user"]) {
        return @"ASR";
    }
    if ([normalized isEqualToString:@"llm"]) {
        return @"LLM";
    }
    return @"文本";
}

- (NSString *)demo_stringForCaseInsensitiveKey:(NSString *)wantedKey inDictionary:(NSDictionary *)dictionary {
    for (NSString *key in dictionary) {
        if ([key caseInsensitiveCompare:wantedKey] == NSOrderedSame) {
            return [self demo_coercedStringFromJSONValue:dictionary[key]];
        }
    }
    return nil;
}

- (NSString *)demo_coercedStringFromJSONValue:(id)value {
    if ([value isKindOfClass:[NSString class]]) {
        return (NSString *)value;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value stringValue];
    }
    return nil;
}

- (NSDictionary *)demo_nestedTranscriptionPayloadIfAny:(NSDictionary *)root {
    return [self demo_nestedTranscriptionPayloadIfAny:root depth:0];
}

- (NSDictionary *)demo_nestedTranscriptionPayloadIfAny:(NSDictionary *)root depth:(NSInteger)depth {
    static const NSInteger kMaxDepth = 8;
    if (depth > kMaxDepth || ![root isKindOfClass:[NSDictionary class]] || root.count == 0) {
        return nil;
    }

    NSString *topic = [self demo_topicStringFromDictionary:root];
    if ([self demo_topicMatchesTranscription:topic]) {
        return root;
    }

    static NSArray<NSString *> *nestedKeys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        nestedKeys = @[ @"data", @"payload", @"content", @"body", @"message", @"inner", @"event" ];
    });

    for (NSString *key in nestedKeys) {
        id node = root[key];
        if ([node isKindOfClass:[NSDictionary class]]) {
            NSDictionary *found = [self demo_nestedTranscriptionPayloadIfAny:(NSDictionary *)node depth:depth + 1];
            if (found != nil) {
                return found;
            }
        } else if ([node isKindOfClass:[NSString class]]) {
            NSString *jsonString = [(NSString *)node stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (jsonString.length == 0) {
                continue;
            }
            NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
            if (data.length == 0) {
                continue;
            }
            NSError *error = nil;
            id parsed = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if ([parsed isKindOfClass:[NSDictionary class]]) {
                NSDictionary *found = [self demo_nestedTranscriptionPayloadIfAny:(NSDictionary *)parsed depth:depth + 1];
                if (found != nil) {
                    return found;
                }
            }
        }
    }

    return nil;
}

- (NSString *)demo_topicStringFromDictionary:(NSDictionary *)dictionary {
    for (NSString *key in dictionary) {
        if ([key caseInsensitiveCompare:@"topic"] == NSOrderedSame) {
            id value = dictionary[key];
            if ([value isKindOfClass:[NSString class]]) {
                return [(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
            if ([value isKindOfClass:[NSNumber class]]) {
                return [[(NSNumber *)value stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
            break;
        }
    }
    return nil;
}

- (BOOL)demo_topicMatchesTranscription:(NSString *)topic {
    if (topic.length == 0) {
        return NO;
    }
    return [topic caseInsensitiveCompare:@"lk.transcription"] == NSOrderedSame;
}

#pragma mark - Helpers

- (void)appendDisplayLine:(NSString *)line {
    if (line.length == 0) {
        return;
    }

    NSString *currentText = self.textView.text ?: @"";
    NSString *nextText = currentText.length > 0 ? [currentText stringByAppendingFormat:@"\n%@", line] : line;
    self.textView.text = nextText;

    NSRange bottom = NSMakeRange(MAX(nextText.length - 1, 0), 1);
    [self.textView scrollRangeToVisible:bottom];
}

- (NSString *)displayStringForJSONObject:(id)jsonObject {
    if (![NSJSONSerialization isValidJSONObject:jsonObject]) {
        return [jsonObject description] ?: @"";
    }

    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (error != nil || jsonData.length == 0) {
        return [jsonObject description] ?: @"";
    }

    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString.length > 0 ? jsonString : ([jsonObject description] ?: @"");
}

@end
