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
//
// The TerminalView handles restarting a subprocess when it exits.
@interface TerminalView : UIView <TerminalKeyboardProtocol> {
@private
  VT100TextView *textView;
  SubProcess *subProcess;
  PTY* pty;
  
  // Keeps track of when the subprocess is stopped, so that we know to start
  // a new one on key press.
  BOOL stopped;
  
  // Determines if this view responds to touch events as copy and paste
  BOOL copyAndPasteEnabled;
}

- (id)initWithCoder:(NSCoder *)decoder;
- (void)setFont:(UIFont*)font;
- (ColorMap*)colorMap;

// Must be invoked to start the sub processes
- (void)startSubProcess;

// TerminalKeyboardProtocol
- (void)receiveKeyboardInput:(NSData*)data;

// Configures terminal behavior for responding to touch events
- (void)setCopyPasteEnabled:(BOOL)enabled;

@end
