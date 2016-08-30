//
//  HBNTRootViewController.m
//  NewTerm
//
//  Created by Adam D on 26/01/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

#import "HBNTRootViewController.h"
#import "HBNTPreferencesRootController.h"
#import "HBNTTerminalSessionViewController.h"

@implementation HBNTRootViewController {
	NSMutableArray *_terminals;
}

- (void)loadView {
	[super loadView];

	_terminals = [NSMutableArray array];

	[self addTerminal];

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addTerminal)];

	self.toolbarItems = @[
		// TODO: this needs an icon
		[[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStylePlain target:self action:@selector(showSettings:)]
	];

	self.navigationController.toolbarHidden = NO;
}

#pragma mark - Tab management

- (void)addTerminal {
	HBNTTerminalSessionViewController *terminalViewController = [[HBNTTerminalSessionViewController alloc] init];

	[self addChildViewController:terminalViewController];
	[terminalViewController willMoveToParentViewController:self];
	[self.view addSubview:terminalViewController.view];
	[terminalViewController didMoveToParentViewController:self];

	[_terminals addObject:terminalViewController];
}

#pragma mark - Callbacks

- (void)showSettings:(UIBarButtonItem *)sender {
	HBNTPreferencesRootController *rootController = [[HBNTPreferencesRootController alloc] initWithTitle:NSLocalizedString(@"SETTINGS", @"Title of Settings page.") identifier:[NSBundle mainBundle].infoDictionary[@"CFBundleIdentifier"]];
	rootController.modalPresentationStyle = UIModalPresentationFormSheet;
	[self.navigationController presentViewController:rootController animated:YES completion:nil];
}

@end
