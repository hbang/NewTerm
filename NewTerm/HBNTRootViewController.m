//
//  HBNTRootViewController.m
//  NewTerm
//
//  Created by Adam D on 26/01/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

#import "HBNTRootViewController.h"
#import "HBNTTerminalSessionViewController.h"
#import "HBNTServer.h"

@implementation HBNTRootViewController {
	NSMutableArray *_terminals;
}

- (void)loadView {
	[super loadView];
	
	_terminals = [NSMutableArray array];
	
	[self addTerminalForServer:[HBNTServer localServer]];
}

- (void)addTerminalForServer:(HBNTServer *)server {
	HBNTTerminalSessionViewController *terminalViewController = [[HBNTTerminalSessionViewController alloc] initWithServer:server];
	
	[self addChildViewController:terminalViewController];
	[terminalViewController willMoveToParentViewController:self];
	[self.view addSubview:terminalViewController.view];
	[terminalViewController didMoveToParentViewController:self];
	
	[_terminals addObject:terminalViewController];
}

@end
