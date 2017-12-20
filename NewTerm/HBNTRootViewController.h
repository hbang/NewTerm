//
//  HBNTRootViewController.h
//  NewTerm
//
//  Created by Adam D on 26/01/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

@class HBNTTerminalSessionViewController;

@interface HBNTRootViewController : UIViewController

- (void)addTerminal;
- (void)removeTerminal:(HBNTTerminalSessionViewController *)viewController;

@property (nonatomic, assign) NSUInteger selectedTabIndex;

@end
