//
//  HBNTPreferencesRootController.m
//  NewTerm
//
//  Created by Adam Demasi on 30/10/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

#import "HBNTPreferencesRootController.h"
#import "HBNTPreferencesRootListController.h"
#import <Preferences/PSSpecifier.h>

@implementation HBNTPreferencesRootController {
    PSListController *_rootListController;
}

#pragma mark - UIViewController

- (void)loadView {
	[super loadView];

	self.contentSizeForViewInPopover = CGSizeMake(320.f, 480.f);

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
		_rootListController = [[HBNTPreferencesRootListController alloc] initForContentSize:self.view.frame.size];
		PSSpecifier *specifier = [[PSSpecifier alloc] init] ;
		specifier.target = _rootListController;
		_rootListController.rootController = self;
		_rootListController.specifier = specifier;
		_rootListController.parentController = self;
	}

	return _rootListController;
}

@end
