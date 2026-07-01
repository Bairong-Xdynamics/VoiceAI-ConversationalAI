//
//  DemoCredentialConfigViewController.m
//  BRAIVoiceRTCDemo
//

#import "DemoCredentialConfigViewController.h"
#import "DemoCredentialDefaultsKeys.h"

@interface DemoCredentialConfigViewController () <UITextFieldDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UITextView *robotKeyTextView;
@property (nonatomic, strong) UITextView *robotTokenTextView;
@property (nonatomic, strong) UITextField *userNameField;
@end

@implementation DemoCredentialConfigViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"配置";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    [self.view addSubview:self.scrollView];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 16.0;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:stack];

    self.robotKeyTextView = [self makeCredentialTextView];
    self.robotTokenTextView = [self makeCredentialTextView];
    self.userNameField = [self makeUserNameField];

    [stack addArrangedSubview:[self labeledEditorWithTitle:@"robotKey（多行，可粘贴）" editor:self.robotKeyTextView]];
    [stack addArrangedSubview:[self labeledEditorWithTitle:@"robotToken（多行，可粘贴）" editor:self.robotTokenTextView]];
    [stack addArrangedSubview:[self labeledEditorWithTitle:@"userName" editor:self.userNameField]];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [stack.topAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.topAnchor constant:16.0],
        [stack.leadingAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.leadingAnchor constant:16.0],
        [stack.trailingAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.trailingAnchor constant:-16.0],
        [stack.bottomAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.bottomAnchor constant:-24.0],
        [stack.widthAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.widthAnchor constant:-32.0]
    ]];

    [self.robotKeyTextView.heightAnchor constraintGreaterThanOrEqualToConstant:100.0].active = YES;
    [self.robotTokenTextView.heightAnchor constraintGreaterThanOrEqualToConstant:140.0].active = YES;
    [self.userNameField.heightAnchor constraintEqualToConstant:44.0].active = YES;

    [self loadCredentialsFromUserDefaults];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isMovingFromParentViewController) {
        [self persistCredentialsToUserDefaults];
    }
}

#pragma mark - UI builders

- (UIToolbar *)keyboardDismissToolbar {
    UIToolbar *bar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 44)];
    bar.items = @[
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
        [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStyleDone target:self action:@selector(endEditingAction)]
    ];
    return bar;
}

- (void)endEditingAction {
    [self.view endEditing:YES];
}

- (UITextView *)makeCredentialTextView {
    UITextView *tv = [[UITextView alloc] init];
    tv.translatesAutoresizingMaskIntoConstraints = NO;
    tv.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
    tv.backgroundColor = [UIColor secondarySystemBackgroundColor];
    tv.textColor = [UIColor labelColor];
    tv.layer.cornerRadius = 8.0;
    tv.layer.masksToBounds = YES;
    tv.autocorrectionType = UITextAutocorrectionTypeNo;
    tv.autocapitalizationType = UITextAutocapitalizationTypeNone;
    tv.spellCheckingType = UITextSpellCheckingTypeNo;
    tv.smartDashesType = UITextSmartDashesTypeNo;
    tv.smartQuotesType = UITextSmartQuotesTypeNo;
    tv.smartInsertDeleteType = UITextSmartInsertDeleteTypeNo;
    tv.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10);
    tv.inputAccessoryView = [self keyboardDismissToolbar];
    return tv;
}

- (UITextField *)makeUserNameField {
    UITextField *f = [[UITextField alloc] init];
    f.translatesAutoresizingMaskIntoConstraints = NO;
    f.borderStyle = UITextBorderStyleRoundedRect;
    f.placeholder = @"userName（可粘贴）";
    f.autocorrectionType = UITextAutocorrectionTypeNo;
    f.autocapitalizationType = UITextAutocapitalizationTypeNone;
    f.spellCheckingType = UITextSpellCheckingTypeNo;
    f.clearButtonMode = UITextFieldViewModeWhileEditing;
    f.returnKeyType = UIReturnKeyDone;
    f.delegate = self;
    f.inputAccessoryView = [self keyboardDismissToolbar];
    [f addTarget:self action:@selector(endEditingAction) forControlEvents:UIControlEventEditingDidEndOnExit];
    return f;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (UIView *)labeledEditorWithTitle:(NSString *)title editor:(UIView *)editor {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = title;
    label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    label.textColor = [UIColor secondaryLabelColor];
    label.numberOfLines = 0;

    UIStackView *col = [[UIStackView alloc] initWithArrangedSubviews:@[label, editor]];
    col.axis = UILayoutConstraintAxisVertical;
    col.spacing = 8.0;
    col.alignment = UIStackViewAlignmentFill;
    col.translatesAutoresizingMaskIntoConstraints = NO;
    return col;
}

#pragma mark - Persistence

- (NSString *)trimmedString:(NSString *)text {
    return [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
}

- (void)loadCredentialsFromUserDefaults {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *key = [ud stringForKey:kDemoCredentialUDRobotKey] ?: @"";
    NSString *token = [ud stringForKey:kDemoCredentialUDRobotToken] ?: @"";
    NSString *user = [ud stringForKey:kDemoCredentialUDUserName] ?: @"";
    self.robotKeyTextView.text = key;
    self.robotTokenTextView.text = token;
    self.userNameField.text = user;
}

- (void)persistCredentialsToUserDefaults {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:[self trimmedString:self.robotKeyTextView.text] forKey:kDemoCredentialUDRobotKey];
    [ud setObject:[self trimmedString:self.robotTokenTextView.text] forKey:kDemoCredentialUDRobotToken];
    [ud setObject:[self trimmedString:self.userNameField.text] forKey:kDemoCredentialUDUserName];
    [ud synchronize];
}

@end
