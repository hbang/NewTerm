// TerminalView.h
// MobileTerminal

#import <UIKit/UIKit.h>
#import "VT100/VT100TextView.h"
#import "VT100/ColorMap.h"
#import "TerminalKeyboard.h"

@class VT100TextView;
@class SubProcess;
@class PTY;

// TerminalView is a wrapper around a subprocess and a VT100 text view, so that
// there can be multiple concurrent terminals/subprocesses running at a time.
// Typically, though, only one terminal is displayed at a time.  It implements
// the terminal keyboard protocol, but only one instance is set as the
// TerminalKeyboards input delegate at any time.
@interface TerminalView : UIView <TerminalKeyboardProtocol> {
@private
  VT100TextView *textView;
  SubProcess *subProcess;
  PTY* pty;
}

- (id)initWithCoder:(NSCoder *)decoder;
- (void)setFont:(UIFont*)font;
- (UIFont*)font;
- (ColorMap*)colorMap;

// TerminalKeyboardProtocol
- (void)receiveKeyboardInput:(NSData*)data;

@end
