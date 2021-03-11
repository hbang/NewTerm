//
//  HBNTPreferencesRootController.m
//  NewTerm
//
//  Created by Adam Demasi on 30/10/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

#import "PreferencesRootController.h"

#if LINK_CEPHEI
#import "../prefs/HBNTPreferencesRootListController.h"
#import <Preferences/PSSpecifier.h>
#include <objc/runtime.h>
#endif

@implementation PreferencesRootController {
#if LINK_CEPHEI
	PSListController *_rootListController;
#endif
}

#pragma mark - UIViewController

- (void)loadView {
	[super loadView];

#if LINK_CEPHEI
	if (self.viewControllers.count == 0) {
		[self pushViewController:self.rootListController animated:NO];
	}
#endif
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	if (@available(iOS 13, *)) {
		return [super preferredStatusBarStyle];
	} else {
		return UIStatusBarStyleLightContent;
	}
}

#pragma mark - PSRootController

#if LINK_CEPHEI
- (PSListController *)rootListController {
	if (!_rootListController) {
		static Class HBNTPreferencesRootListController;
		static dispatch_once_t onceToken;
		dispatch_once(&onceToken, ^{
			// Lazy load the preference bundle and the root list controller class
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
#endif

@end
