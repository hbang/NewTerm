@class HBNTKeyboardButton;

@interface HBNTKeyboardToolbar : UIToolbar

@property (nonatomic, strong) HBNTKeyboardButton *ctrlKey, *metaKey, *tabKey;
@property (nonatomic, strong) HBNTKeyboardButton *upKey, *downKey, *leftKey, *rightKey;

@end
