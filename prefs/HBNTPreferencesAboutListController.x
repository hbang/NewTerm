//
//  HBNTPreferencesAboutListController.m
//  NewTerm
//
//  Created by Adam Demasi on 30/10/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

#import "HBNTPreferencesAboutListController.h"

@interface LogoHeaderView : UIView

@end

@implementation HBNTPreferencesAboutListController

#pragma mark - Preferences

+ (NSString *)hb_specifierPlist {
	return @"About";
}

#pragma mark - UIViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	self.table.tableHeaderView = [[%c(LogoHeaderView) alloc] init];
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];

	CGRect headerFrame = self.table.tableHeaderView.frame;
	headerFrame.size = [self.table.tableHeaderView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
	self.table.tableHeaderView.frame = headerFrame;
}

@end
