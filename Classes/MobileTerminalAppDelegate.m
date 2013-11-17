// MobileTerminalAppDelegate.m
// MobileTerminal

#import "MobileTerminalAppDelegate.h"
#import "MobileTerminalViewController.h"

#import "Preferences/Settings.h"
#import "Preferences/MenuSettings.h"

@implementation MobileTerminalAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	_terminalViewController = [[MobileTerminalViewController alloc] init];
	_navigationController = [[UINavigationController alloc] initWithRootViewController:_terminalViewController];
	_window.rootViewController = _navigationController;
	[_window makeKeyAndVisible];
	
	[UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;
}

@end
