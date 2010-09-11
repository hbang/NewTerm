// GestureRegistry.h
// MobileTerminal

#import <Foundation/Foundation.h>

#import "Terminal/TerminalKeyboard.h"

@class MobileTerminalViewController;
@class GestureSettings;
@class GestureResponder;

// This class is responsible for issueing gesture actions with the settings
// library.  The gesture actions are things like "hide and show keyboard" or 
// "left arrow key" that are performed in response to a gesture such as a swipe.
@interface GestureActionRegistry : NSObject<TerminalInputProtocol> {
@private
  id<TerminalInputProtocol> terminalInput;
  MobileTerminalViewController* viewController;
  GestureSettings* gestureSettings;
}

@property (nonatomic, retain) id<TerminalInputProtocol> terminalInput;
@property (nonatomic, retain) IBOutlet MobileTerminalViewController *viewController;

// Invoked by a gesture action to forward input on to the keyboard
- (void)receiveKeyboardInput:(NSData*)data;

@end
