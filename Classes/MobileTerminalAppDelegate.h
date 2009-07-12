// MobileTerminalAppDelegate.h
// MobileTerminal

#import <UIKit/UIKit.h>

@class MobileTerminalViewController;

@interface MobileTerminalAppDelegate : NSObject <UIApplicationDelegate> {
@private
  UIWindow *window;
  MobileTerminalViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet MobileTerminalViewController *viewController;

@end

