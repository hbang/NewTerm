//
//  HBNTPreferencesRootListController.m
//  NewTerm
//
//  Created by Adam Demasi on 30/10/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

#import "HBNTPreferencesRootListController.h"

@implementation HBNTPreferencesRootListController

#pragma mark - Preferences

+ (NSString *)hb_specifierPlist {
	return @"Root";
}

#pragma mark - UIViewController

- (void)loadView {
	[super loadView];

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];
}

#pragma mark - Callbacks

- (void)dismiss {
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
