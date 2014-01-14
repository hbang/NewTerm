// MobileTerminalAppDelegate.m
// MobileTerminal

#import "MobileTerminalAppDelegate.h"
#import "MobileTerminalViewController.h"

#import "Preferences/Settings.h"
#import "Preferences/MenuSettings.h"

@implementation MobileTerminalAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	[UINavigationBar appearance].barStyle = UIBarStyleBlack;
	[UIToolbar appearance].barStyle = UIBarStyleBlack;
	[UITableView appearance].backgroundColor = [UIColor blackColor];
	[UITableView appearance].separatorColor = [UIColor colorWithWhite:0 alpha:1];
	[UITableViewCell appearance].backgroundColor = [UIColor colorWithWhite:0.2078431373f alpha:1];
	[UITableViewCell appearance].textColor = [UIColor whiteColor];
	
	UIView *selectedBackgroundView = [[[UIView alloc] init] autorelease];
	selectedBackgroundView.backgroundColor = [UIColor colorWithWhite:0.3529411765f alpha:1];
	[UITableViewCell appearance].selectedBackgroundView = selectedBackgroundView;
	
	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	
	if ([_window respondsToSelector:@selector(setTintColor:)]) {
		_window.tintColor = [UIColor colorWithWhite:0.7f alpha:1];
	}
	
	_terminalViewController = [[MobileTerminalViewController alloc] init];
	_navigationController = [[UINavigationController alloc] initWithRootViewController:_terminalViewController];
	_window.rootViewController = _navigationController;
	[_window makeKeyAndVisible];
	
	[UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;
	
	if (IS_IOS_7) {
		UIToolbar *statusBarToolbar = [[[UIToolbar alloc] initWithFrame:[UIApplication sharedApplication].statusBarFrame] autorelease];
		statusBarToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		statusBarToolbar.translucent = YES;
		[_window addSubview:statusBarToolbar];
	}
}

- (void)dealloc {
	[_window release];
	[_terminalViewController release];
	[_navigationController release];
	
	[super dealloc];
}

@end
