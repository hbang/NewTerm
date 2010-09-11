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
  NSMutableArray* swipeGestureRecognizers;
}

@property (nonatomic, retain) IBOutlet MobileTerminalViewController *viewController;

// Swipes can be disabled so that they don't interfere with gestures handled
// directly by the other views (such as copy and paste)
- (void)setSwipesEnabled:(BOOL)enabled;

@end
