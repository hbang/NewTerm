#import "HBNTTextInputBase.h"

// Protocol implemented by listener of keyboard events
@protocol HBNTTerminalInputProtocol

@required
- (void)receiveKeyboardInput:(NSData *)data;

@end

@protocol HBNTTerminalKeyboardProtocol <HBNTTerminalInputProtocol>

@end

@interface HBNTTerminalKeyInput : HBNTTextInputBase

@property (nonatomic, strong) UITextView *textView;

// TODO: i think this should be weak?
@property (nonatomic, strong) id <HBNTTerminalKeyboardProtocol> terminalInputDelegate;

@end
