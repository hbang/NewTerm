// MobileTerminalAppDelegate.h
// MobileTerminal

#import <UIKit/UIKit.h>
#import "MobileTerminalViewController.h"
#import "Preferences/PreferencesViewController.h"

@class Settings;

@interface MobileTerminalAppDelegate : UIResponder <UIApplicationDelegate, MobileTerminalInterfaceDelegate>

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, retain) MobileTerminalViewController *terminalViewController;
@property (nonatomic, retain) PreferencesViewController *preferencesViewController;

- (void)preferencesButtonPressed;
- (void)rootViewDidAppear;

@end

