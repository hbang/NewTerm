// MobileTerminalViewController.h
// MobileTerminal

#import <UIKit/UIKit.h>
#import "TerminalKeyboard.h"

@class VT100TextView;
@class SubProcess;
@class PTY;
@class TerminalKeyboard;

@interface MobileTerminalViewController : UIViewController <TerminalKeyboardProtocol> {
@private
  VT100TextView *vt100TextView;
  SubProcess *subProcess;
  PTY* pty;
  TerminalKeyboard* terminalKeyboard;
  BOOL keyboardShown;
}

@property (nonatomic, retain) IBOutlet VT100TextView *vt100TextView;

- (void)receiveKeyboardInput:(NSData*)data;

@end

