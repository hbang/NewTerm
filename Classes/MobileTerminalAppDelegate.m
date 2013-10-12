// MobileTerminalAppDelegate.m
// MobileTerminal

#import "MobileTerminalAppDelegate.h"
#import "MobileTerminalViewController.h"

#import "Preferences/Settings.h"
#import "Preferences/MenuSettings.h"

@interface MobileTerminalAppDelegate () {
	BOOL _inPreferences;
}

@end

@implementation MobileTerminalAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	_inPreferences = NO;
	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	_terminalViewController = [[MobileTerminalViewController alloc] init];
	_navigationController = [[UINavigationController alloc] initWithRootViewController:_terminalViewController];
	_window.rootViewController = _navigationController;
	[_window makeKeyAndVisible];
}

static const NSTimeInterval kAnimationDuration = 1.00f;

- (void)preferencesButtonPressed {
	_inPreferences = YES;
	[_navigationController pushViewController:_preferencesViewController animated:YES];
}

- (void)rootViewDidAppear
{
	if (_inPreferences) {
		[[Settings sharedInstance] persist];
	}
	_inPreferences = YES;
}

@end
