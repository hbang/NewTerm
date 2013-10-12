// MobileTerminalAppDelegate.h
// MobileTerminal

#import <UIKit/UIKit.h>
#import "MobileTerminalViewController.h"

@interface MobileTerminalAppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, retain) MobileTerminalViewController *terminalViewController;

@end
