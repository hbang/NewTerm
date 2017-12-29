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
#import "HBNTTabToolbar.h"
#import "HBNTTabCollectionViewCell.h"

@interface HBNTRootViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@end

@implementation HBNTRootViewController {
	NSMutableArray *_terminals;
	NSUInteger _selectedTabIndex;

	HBNTTabToolbar *_tabToolbar;
	UIToolbar *_bottomToolbar;
	UICollectionView *_tabsCollectionView;
}

- (void)loadView {
	[super loadView];

	self.automaticallyAdjustsScrollViewInsets = NO;
	self.navigationController.navigationBarHidden = YES;

	_terminals = [NSMutableArray array];

	_tabToolbar = [[HBNTTabToolbar alloc] init];
	_tabToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[_tabToolbar.addButton addTarget:self action:@selector(addTerminal) forControlEvents:UIControlEventTouchUpInside];

	_tabsCollectionView = _tabToolbar.tabsCollectionView;
	_tabsCollectionView.dataSource = self;
	_tabsCollectionView.delegate = self;

	[self.view addSubview:_tabToolbar];

	_bottomToolbar = [[UIToolbar alloc] init];
	_bottomToolbar.items = @[
		[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettings:)]
	];
	[self.view addSubview:_bottomToolbar];

	[self addTerminal];
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];

	CGFloat barHeight = [UIScreen mainScreen].bounds.size.height < 600.f ? 32.f : 44.f;
	CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;

	_tabToolbar.frame = CGRectMake(0, 0, self.view.frame.size.width, statusBarHeight + barHeight);
	_bottomToolbar.frame = CGRectMake(0, self.view.frame.size.height - barHeight, self.view.frame.size.width, barHeight);

	for (HBNTTerminalSessionViewController *viewController in _terminals) {
		viewController.barInsets = UIEdgeInsetsMake(_tabToolbar.frame.size.height, 0, _bottomToolbar.frame.size.height, 0);
	}
}

#pragma mark - Tab management

- (void)addTerminal {
	HBNTTerminalSessionViewController *terminalViewController = [[HBNTTerminalSessionViewController alloc] init];

	[self addChildViewController:terminalViewController];
	[terminalViewController willMoveToParentViewController:self];
	[self.view insertSubview:terminalViewController.view belowSubview:_tabToolbar];
	[terminalViewController didMoveToParentViewController:self];

	[_terminals addObject:terminalViewController];
	[_tabsCollectionView reloadData];
	self.selectedTabIndex = _terminals.count - 1;
}

- (void)removeTerminalAtIndex:(NSUInteger)index {
	HBNTTerminalSessionViewController *terminalViewController = [_terminals objectAtIndex:index];

	[terminalViewController removeFromParentViewController];
	[terminalViewController.view removeFromSuperview];

	[_terminals removeObjectAtIndex:index];

	// if this was the last tab, make a new tab. otherwise select the closest tab we have available
	if (_terminals.count == 0) {
		[self addTerminal];
	} else {
		[_tabsCollectionView reloadData];
		self.selectedTabIndex = index >= _terminals.count ? index - 1 : index;
	}
}

- (void)removeTerminal:(HBNTTerminalSessionViewController *)viewController {
	NSUInteger index = [_terminals indexOfObject:viewController];

	if (index == NSNotFound) {
		HBLogWarn(@"asked to remove terminal that doesn’t exist? %@", viewController);
	} else {
		[self removeTerminalAtIndex:index];
	}
}

- (void)removeTerminalButtonTapped:(UIButton *)button {
	[self removeTerminalAtIndex:button.tag];
}

- (NSUInteger)selectedTabIndex {
	return _selectedTabIndex;
}

- (void)setSelectedTabIndex:(NSUInteger)selectedTabIndex {
	// this will crash if out of bounds, but i’d rather it crash anyway
	HBNTTerminalSessionViewController *previousViewController = _terminals[_selectedTabIndex];
	HBNTTerminalSessionViewController *newViewController = _terminals[selectedTabIndex];

	_selectedTabIndex = selectedTabIndex;

	// call the appropriate view controller lifecycle methods on the previous and new view controllers
	[previousViewController viewWillDisappear:NO];
	previousViewController.view.hidden = YES;
	[previousViewController viewDidDisappear:NO];

	[newViewController viewWillAppear:NO];
	newViewController.view.hidden = NO;
	[newViewController viewDidAppear:NO];

	[_tabsCollectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:selectedTabIndex inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionCenteredVertically];
}

#pragma mark - Callbacks

- (void)showSettings:(UIBarButtonItem *)sender {
	HBNTPreferencesRootController *rootController = [[HBNTPreferencesRootController alloc] initWithTitle:NSLocalizedString(@"SETTINGS", @"Title of Settings page.") identifier:[NSBundle mainBundle].infoDictionary[@"CFBundleIdentifier"]];
	rootController.modalPresentationStyle = UIModalPresentationFormSheet;
	[self.navigationController presentViewController:rootController animated:YES completion:nil];
}

#pragma mark - Collection view

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return _terminals.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	HBNTTerminalSessionViewController *terminalViewController = _terminals[indexPath.row];

	HBNTTabCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TabCell" forIndexPath:indexPath];
	cell.textLabel.text = terminalViewController.title;
	cell.selected = _selectedTabIndex == indexPath.row;
	cell.closeButton.tag = indexPath.row;
	[cell.closeButton addTarget:self action:@selector(removeTerminalButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	self.selectedTabIndex = indexPath.row;
}

@end
