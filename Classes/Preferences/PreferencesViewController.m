// PreferencesViewController.m
// MobileTerminal

#import "PreferencesViewController.h"
#import "MenuSettingsViewController.h"
#import "GestureSettingsViewController.h"
#import "Settings.h"

@interface PreferencesViewController () {
	NSArray *_sections;
	NSArray *_controllers;
}

@end

@implementation PreferencesViewController

- (void)loadView {
	[super loadView];
	
	self.title = @"Settings";
	
	_sections = [@[
		@"Shortcut Menu",
		@"Gestures"
	] retain];
	
	_controllers = [@[
		[[[MenuSettingsViewController alloc] init] autorelease],
		[[[GestureSettingsViewController alloc] init] autorelease]
	] retain];
	
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneTapped)] autorelease];
	}
}

- (void)dealloc {
	[_sections release];
	[_controllers release];
	[super dealloc];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleDefault;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[Settings sharedInstance] persist];
}

- (void)doneTapped {
	[self.navigationController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _sections.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	}
	
	cell.textLabel.text = [_sections objectAtIndex:indexPath.row];
	
	if ([_controllers objectAtIndex:indexPath.row]) {
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	UIViewController *itemController = [_controllers objectAtIndex:indexPath.row];
	[self.navigationController pushViewController:itemController animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	return [NSString stringWithFormat:@"MobileTerminal\nVersion %@", [[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleShortVersionString"]];
}

@end
