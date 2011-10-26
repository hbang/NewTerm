// TerminalKeyboard.h
// MobileTerminal

#import <UIKit/UIKit.h>

// Protocol implemented by listener of keyboard events
@protocol TerminalInputProtocol
@required
- (void)receiveKeyboardInput:(NSData*)data;
@end

@protocol TerminalKeyboardProtocol <TerminalInputProtocol>
@required
- (void)fillDataWithSelection:(NSMutableData*)data;
@end

// The terminal keyboard.  This is an opaque view that triggers rendering of the
// keyboard on the screen -- the keyboard is not rendered in this view itself.
// There is typically only ever one instance of TerminalKeyboard.
@interface TerminalKeyboard : UIView {
@private
  UIView <UITextInput>* inputTextField;
  id<TerminalKeyboardProtocol> inputDelegate;
}

@property (nonatomic, retain) id<TerminalKeyboardProtocol> inputDelegate;

// Show and hide the keyboard, respectively.  Callers can listen to system
// keyboard notifications to get notified when the keyboard is shown.
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;

@end