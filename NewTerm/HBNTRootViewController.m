//
//  HBNTRootViewController.m
//  NewTerm
//
//  Created by Adam D on 26/01/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

#import "HBNTRootViewController.h"
#import "HBNTPreferencesRootController.h"
#import "HBNTServer.h"
#import "HBNTTerminalSessionViewController.h"

@implementation HBNTRootViewController {
	NSMutableArray *_terminals;
}

- (void)loadView {
	[super loadView];

	_terminals = [NSMutableArray array];

	[self addTerminalForServer:[HBNTServer localServer]];

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStylePlain target:self action:@selector(showSettings:)];
}

- (void)addTerminalForServer:(HBNTServer *)server {
	HBNTTerminalSessionViewController *terminalViewController = [[HBNTTerminalSessionViewController alloc] initWithServer:server];

	[self addChildViewController:terminalViewController];
	[terminalViewController willMoveToParentViewController:self];
	[self.view addSubview:terminalViewController.view];
	[terminalViewController didMoveToParentViewController:self];

	[_terminals addObject:terminalViewController];
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];

	UIEdgeInsets inset = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, self.bottomLayoutGuide.length, 0);

	for (HBNTTerminalSessionViewController *terminalViewController in _terminals) {
		terminalViewController.textView.contentInset = inset;
	}
}

#pragma mark - Callbacks

- (void)showSettings:(UIBarButtonItem *)sender {
	HBNTPreferencesRootController *rootController = [[HBNTPreferencesRootController alloc] initWithTitle:L18N(@"Settings") identifier:[NSBundle mainBundle].infoDictionary[@"CFBundleIdentifier"]];
	[self.navigationController presentViewController:rootController animated:YES completion:nil];
}

@end
