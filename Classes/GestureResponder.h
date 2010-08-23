// GestureResponder.h
// MobileTerminal

#import <Foundation/Foundation.h>

@class MobileTerminalViewController;
@class GestureSettings;

// Handles recognition of all gestures and invokes the appropriate action
@interface GestureResponder : NSObject {
@private
  MobileTerminalViewController* viewController;
  GestureSettings* gestureSettings;
}

@property (nonatomic, retain) IBOutlet MobileTerminalViewController *viewController;

@end
