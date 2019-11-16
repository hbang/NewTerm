//
//  HBNTPreferencesRootListController.m
//  NewTerm
//
//  Created by Adam Demasi on 30/10/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

#import "HBNTPreferencesRootListController.h"
#import <CepheiPrefs/HBAppearanceSettings.h>

@implementation HBNTPreferencesRootListController

#pragma mark - Preferences

+ (NSString *)hb_specifierPlist {
	return @"Root";
}

#pragma mark - UIViewController

- (void)loadView {
	[super loadView];

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss)];

	HBAppearanceSettings *appearance = [[HBAppearanceSettings alloc] init];
	appearance.tintColor = [UIApplication sharedApplication].keyWindow.tintColor;
	if (@available(iOS 13.0, *)) {
	} else {
		appearance.translucentNavigationBar = YES;
		appearance.tableViewCellTextColor = [UIColor whiteColor];
		appearance.tableViewCellBackgroundColor = [UIColor colorWithWhite:0.055f alpha:1];
		appearance.tableViewCellSeparatorColor = [UIColor colorWithWhite:0.149f alpha:1];
		appearance.tableViewCellSelectionColor = appearance.tableViewCellSeparatorColor;
		appearance.tableViewBackgroundColor = [UIColor colorWithWhite:0.089f alpha:1];
	}
	self.hb_appearanceSettings = appearance;
}

#pragma mark - Callbacks

- (void)dismiss {
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
