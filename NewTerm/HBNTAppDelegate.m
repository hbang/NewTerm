//
//  HBNTAppDelegate.m
//  NewTerm
//
//  Created by Adam D on 20/07/2014.
//  Copyright (c) 2014 HASHBANG Productions. All rights reserved.
//

#import "HBNTAppDelegate.h"
#import "HBNTRootViewController.h"

@implementation HBNTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	UIColor *textColor = [UIColor whiteColor];
	UIColor *tintColor = [UIColor colorWithRed:76.f / 255.f green:161.f / 255.f blue:1 alpha:1];
	UIColor *backgroundColor = [UIColor colorWithWhite:26.f / 255.f alpha:1];
	UIColor *lightTintColor = [UIColor colorWithWhite:60.f / 255.f alpha:1];

	[UINavigationBar appearance].barStyle = UIBarStyleBlack;
	[UIToolbar appearance].barStyle = UIBarStyleBlack;

	[UITableView appearance].backgroundColor = backgroundColor;
	[UITableViewCell appearance].backgroundColor = backgroundColor;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	// this is deprecated but apple doesn’t exactly provide an easy, supported way to do this
	[UITableViewCell appearance].textColor = textColor;
#pragma clang diagnostic pop

	[UINavigationBar appearance].titleTextAttributes = @{ NSForegroundColorAttributeName: textColor };
	[UITextField appearance].textColor = textColor;

	[UITableView appearance].separatorColor = lightTintColor;
	[UITextField appearance].keyboardAppearance = UIKeyboardAppearanceDark;
	[UIScrollView appearance].keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;

	_window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	_window.tintColor = tintColor;
	_window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[HBNTRootViewController alloc] init]];
	[_window makeKeyAndVisible];

	return YES;
}

@end
