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
#import <version.h>

@interface HBNTRootViewController () <UICollectionViewDelegate, UICollectionViewDataSource>

@end

@implementation HBNTRootViewController {
	NSMutableArray *_terminals;
	NSUInteger _selectedTabIndex;

	HBNTTabToolbar *_tabToolbar;
	UICollectionView *_tabsCollectionView;
}

- (void)loadView {
	[super loadView];

	self.navigationController.navigationBarHidden = YES;

	_terminals = [NSMutableArray array];

	_tabToolbar = [[HBNTTabToolbar alloc] init];
	_tabToolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[_tabToolbar.addButton addTarget:self action:@selector(addTerminal) forControlEvents:UIControlEventTouchUpInside];

	_tabsCollectionView = _tabToolbar.tabsCollectionView;
	_tabsCollectionView.dataSource = self;
	_tabsCollectionView.delegate = self;

	[self.view addSubview:_tabToolbar];
		
	[self setToolbarItems:@[
		[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"] style:UIBarButtonItemStylePlain target:self action:@selector(showSettings:)],
		[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
		[[UIBarButtonItem alloc] initWithTitle:@"▲" style:UIBarButtonItemStylePlain target:self action:@selector(showKeyboard)]
	] animated:NO];
	[self.navigationController setToolbarHidden:NO animated:NO];
	
	[self addTerminal];
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];

	CGFloat barHeight = [UIScreen mainScreen].bounds.size.height < 600.f ? 32.f : 40.f;
	CGFloat statusBarHeight = IS_IOS_OR_NEWER(iOS_7_0) ? [UIApplication sharedApplication].statusBarFrame.size.height : 0;

	_tabToolbar.frame = CGRectMake(0, 0, self.view.frame.size.width, statusBarHeight + barHeight);

	UIEdgeInsets barInsets = UIEdgeInsetsMake(barHeight, 0, 0, 0);

	for (HBNTTerminalSessionViewController *viewController in _terminals) {
		viewController.barInsets = barInsets;
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
	[_tabsCollectionView layoutIfNeeded];
	self.selectedTabIndex = _terminals.count - 1;
	[_tabsCollectionView reloadData];
}

- (void)removeTerminalAtIndex:(NSUInteger)index {
	HBNTTerminalSessionViewController *terminalViewController = _terminals[index];

	[terminalViewController removeFromParentViewController];
	[terminalViewController.view removeFromSuperview];

	[_terminals removeObjectAtIndex:index];

	// if this was the last tab, make a new tab. otherwise select the closest tab we have available
	if (_terminals.count == 0) {
		[self addTerminal];
	} else {
		[_tabsCollectionView reloadData];
		[_tabsCollectionView layoutIfNeeded];
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
	// if this is what’s already selected, just select it again and return
	if (selectedTabIndex == _selectedTabIndex) {
		[_tabsCollectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:_selectedTabIndex inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionCenteredVertically];
		return;
	}

	NSUInteger oldSelectedTabIndex = _selectedTabIndex < _terminals.count ? _selectedTabIndex : NSUIntegerMax;
	
	// if the previous index is now out of bounds, just use nil as our previous. the tab and view
	// controller were removed so we don’t need to do anything
	HBNTTerminalSessionViewController *previousViewController = _selectedTabIndex < _terminals.count ? _terminals[_selectedTabIndex] : nil;
	HBNTTerminalSessionViewController *newViewController = _terminals[selectedTabIndex];

	_selectedTabIndex = selectedTabIndex;

	// call the appropriate view controller lifecycle methods on the previous and new view controllers
	[previousViewController viewWillDisappear:NO];
	previousViewController.view.hidden = YES;
	[previousViewController viewDidDisappear:NO];

	[newViewController viewWillAppear:NO];
	newViewController.view.hidden = NO;
	[newViewController viewDidAppear:NO];

	[_tabsCollectionView performBatchUpdates:^{
		if (oldSelectedTabIndex != NSUIntegerMax) {
			[_tabsCollectionView deselectItemAtIndexPath:[NSIndexPath indexPathForItem:oldSelectedTabIndex inSection:0] animated:NO];
		}

		[_tabsCollectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:selectedTabIndex inSection:0] animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
	} completion:^(BOOL finished) {
		// TODO: hack because the previous tab doesn’t deselect for some reason and ugh i hate this
		[_tabsCollectionView reloadData];
	}];
}

#pragma mark - Callbacks

- (void)showSettings:(UIBarButtonItem *)sender {
	HBNTPreferencesRootController *rootController = [[HBNTPreferencesRootController alloc] initWithTitle:NSLocalizedString(@"SETTINGS", @"Title of Settings page.") identifier:[NSBundle mainBundle].infoDictionary[@"CFBundleIdentifier"]];
	rootController.modalPresentationStyle = UIModalPresentationFormSheet;
	[self.navigationController presentViewController:rootController animated:YES completion:nil];
}

- (void)showKeyboard {
	HBNTTerminalSessionViewController *viewController = _terminals[_selectedTabIndex];
	[viewController becomeFirstResponder];
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

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	// hardcode a width for now, just so we work on ios 6. to be worked on…
	return CGSizeMake(100, _tabsCollectionView.frame.size.height);
}

@end
