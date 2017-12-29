//
//  HBNTPreferencesRootController.m
//  NewTerm
//
//  Created by Adam Demasi on 30/10/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

#import "HBNTPreferencesRootController.h"
#import "../prefs/HBNTPreferencesRootListController.h"
#import <Preferences/PSSpecifier.h>
#include <objc/runtime.h>

@implementation HBNTPreferencesRootController {
    PSListController *_rootListController;
}

#pragma mark - UIViewController

- (void)loadView {
	[super loadView];

	if (self.viewControllers.count == 0) {
		[self pushViewController:self.rootListController animated:NO];
	}
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

#pragma mark - PSRootController

- (PSListController *)rootListController {
	if (!_rootListController) {
		static Class HBNTPreferencesRootListController;
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			// lazy load the preference bundle and the root list controller class
			NSURL *prefsBundleURL = [[NSBundle mainBundle] URLForResource:@"NewTermPreferences" withExtension:@"bundle" subdirectory:@"PreferenceBundles"];
			[[NSBundle bundleWithURL:prefsBundleURL] load];
			HBNTPreferencesRootListController = objc_getClass("HBNTPreferencesRootListController");
		});

		_rootListController = [[HBNTPreferencesRootListController alloc] initForContentSize:self.view.frame.size];
		PSSpecifier *specifier = [[PSSpecifier alloc] init];
		specifier.target = _rootListController;
		_rootListController.rootController = (PSViewController *)self;
		_rootListController.specifier = specifier;
		_rootListController.parentController = (PSViewController *)self;
	}

	return _rootListController;
}

@end
