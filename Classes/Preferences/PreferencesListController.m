// PreferencesListController.m
// MobileTerminal

#import "PreferencesListController.h"
#import "MenuSettingsViewController.h"
#import "GestureSettingsViewController.h"
#import "Settings.h"

@interface PreferencesListController () {
	NSArray *_sections;
	NSArray *_controllers;
}

@end

@implementation PreferencesListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"MobileTerminal" target:self] retain];
	}
	
	return _specifiers;
}

- (void)loadView {
	[super loadView];
	
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneTapped)] autorelease];
	}
}

- (void)doneTapped {
	[self.navigationController dismissViewControllerAnimated:YES completion:NULL];
}

@end
