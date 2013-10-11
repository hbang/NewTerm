// TerminalController.h
// MobileTerminal

#import <UIKit/UIKit.h>
#import "TerminalKeyboard.h"

@class ColorMap;
@class VT100TableViewController;
@class SubProcess;
@class PTY;

// TerminalView is a wrapper around a subprocess and a VT100 text view, so that
// there can be multiple concurrent terminals/subprocesses running at a time.
// Typically, though, only one terminal is displayed at a time.	 It implements
// the terminal keyboard protocol, but only one instance is set as the
// TerminalKeyboards input delegate at any time.
//
// The TerminalView handles restarting a subprocess when it exits.
@interface TerminalController : NSObject <TerminalKeyboardProtocol>

@property (nonatomic, retain) VT100TableViewController *tableViewController;

- (void)setFont:(UIFont *)font;
- (ColorMap *)colorMap;

// Must be invoked to start the sub processes
- (void)startSubProcess;

// TerminalKeyboardProtocol
- (void)receiveKeyboardInput:(NSData *)data;

// Configures terminal behavior for responding to touch events
- (void)setCopyPasteEnabled:(BOOL)enabled;

@end
