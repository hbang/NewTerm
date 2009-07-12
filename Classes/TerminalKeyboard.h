// TerminalKeyboard.h
// MobileTerminal

#import <UIKit/UIKit.h>

@class InputHandler;

// Protocol implemented by listener of keyboard events
@protocol TerminalKeyboardProtocol
@required
- (void)receiveKeyboardInput:(NSData*)data;
@end

// The terminal view.  This is an opaque view that triggers rendering of the
// keyboard on the screen -- the keyboard is not rendered in this view itself.
@interface TerminalKeyboard : UIView {
@private
  InputHandler* inputHandler;
  id<TerminalKeyboardProtocol> inputDelegate;
}

@property (nonatomic, retain) id<TerminalKeyboardProtocol> inputDelegate;

// Show and hide the keyboard, respectively.  Callers can listen to system
// keyboard notifications to get notified when the keyboard is shown.
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;

@end