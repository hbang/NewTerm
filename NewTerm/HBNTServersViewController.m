//
//  HBNTServersViewController.m
//  NewTerm
//
//  Created by Adam D on 20/07/2014.
//  Copyright (c) 2014 HASHBANG Productions. All rights reserved.
//

#import "HBNTServersViewController.h"
#import "HBNTConfigureServerViewController.h"
#import "HBNTServer.h"
#import "HBNTServerTableViewCell.h"
#import "HBNTTerminalSessionViewController.h"

@interface UITableViewHeaderFooterView ()

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier; // wtf?

@end

@implementation HBNTServersViewController {
	NSMutableArray *_servers;
	NSAttributedString *_infoAttributedString;
}

- (void)loadView {
	[super loadView];
	
	self.title = L18N(@"Servers");
	self.navigationItem.leftBarButtonItem = _settingsBarButtonItem;
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	HBNTServer *localTerminal = [[HBNTServer alloc] init];
	localTerminal.name = [UIDevice currentDevice].name;
	localTerminal.username = @"mobile";
	localTerminal.localTerminal = YES;
	
	HBNTServer *yivo = [[HBNTServer alloc] init];
	yivo.name = @"yivo";
	yivo.host = @"192.168.1.4";
	yivo.username = @"kirb";
	
	HBNTServer *hypnotoad = [[HBNTServer alloc] init];
	hypnotoad.name = @"cephei";
	hypnotoad.host = @"192.168.1.2";
	hypnotoad.username = @"kirb";
	
	HBNTServer *nibbler = [[HBNTServer alloc] init];
	nibbler.name = @"nibbler";
	nibbler.host = @"192.168.1.3";
	nibbler.port = 2222;
	nibbler.username = @"kirb";
	
	_servers = [@[ localTerminal, hypnotoad, nibbler, yivo ] mutableCopy];
	
	NSDictionary *info = [NSBundle mainBundle].infoDictionary;
	
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@ (%@)", info[@"CFBundleName"], info[@"CFBundleShortVersionString"], info[@"CFBundleVersion"]] attributes:@{
		NSFontAttributeName: [UIFont systemFontOfSize:16.f],
		NSForegroundColorAttributeName: [UITableView appearance].separatorColor
	}];
	
	[attributedString addAttributes:@{
		NSFontAttributeName: [UIFont boldSystemFontOfSize:16.f]
	} range:NSMakeRange(0, ((NSString *)info[@"CFBundleName"]).length)];
	
	_infoAttributedString = [attributedString copy];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	[self.navigationItem setLeftBarButtonItem:editing ? _addBarButtonItem : _settingsBarButtonItem animated:animated];
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
	_infoButton.frame = CGRectMake(0, self.tableView.frame.size.height - self.topLayoutGuide.length - 44.f, self.tableView.frame.size.width, 44.f);
}

#pragma mark - Actions

- (IBAction)settingsTapped {
	// TODO: implement settings
}

- (IBAction)addTapped {
	UINavigationController *addController = [[UINavigationController alloc] initWithRootViewController:[[HBNTConfigureServerViewController alloc] initWithStyle:UITableViewStyleGrouped]];
	[self.navigationController presentViewController:addController animated:YES completion:nil];
}

- (IBAction)infoTapped {
	// TODO: implement about
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _servers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"ServerCell";
	HBNTServerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (!cell) {
		cell = [[HBNTServerTableViewCell alloc] initWithReuseIdentifier:CellIdentifier];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	cell.server = _servers[indexPath.row];
	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return indexPath.row != 0;
}

/*
- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	[self.navigationController pushViewController:[[HBNTTerminalSessionViewController alloc] initWithServer:_servers[indexPath.row]] animated:YES];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	static NSString *CellIdentifier = @"VersionFooter";
	UITableViewHeaderFooterView *view = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:CellIdentifier];
	
	if (!view) {
		view = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:CellIdentifier];
		view.backgroundView = [[UIView alloc] init];
		
		_infoButton = [UIButton buttonWithType:UIButtonTypeSystem];
		_infoButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleTopMargin;
		_infoButton.frame = CGRectMake(0, 66.f, view.contentView.frame.size.width, view.contentView.frame.size.height - 66.f);
		[_infoButton setAttributedTitle:_infoAttributedString forState:UIControlStateNormal];
		[view.contentView addSubview:_infoButton];
	}
	
	return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return 110.f;
}

@end
