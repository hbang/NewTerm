@interface HBNTKeyboardButton : UIButton

+ (instancetype)buttonWithTitle:(NSString *)title;
+ (instancetype)buttonWithTitle:(NSString *)title target:(id)target action:(SEL)action;

@end
