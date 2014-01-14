//
//  PreferencesRootController.m
//  MobileTerminal
//
//  Created by Adam D on 10/11/2013.
//
//

#import "PreferencesRootController.h"
#import "PreferencesListController.h"

@interface PreferencesRootController () {
    PSListController *_rootListController;
}

@end

@implementation PreferencesRootController

#pragma mark - UIViewController

- (void)loadView {
	[super loadView];
	
	self.contentSizeForViewInPopover = CGSizeMake(320.f, 480.f);
	
	if (self.viewControllers.count == 0) {
		[self pushViewController:self.rootListController animated:NO];
	}
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

#pragma mark - PSRootController

- (PSListController *)rootListController {
	if (!_rootListController) {
		_rootListController = [[PreferencesListController alloc] initForContentSize:self.view.frame.size];
		PSSpecifier *specifier = [[[PSSpecifier alloc] init] autorelease];
		specifier.target = _rootListController;
		_rootListController.rootController = self;
		_rootListController.specifier = specifier;
		_rootListController.parentController = self;
	}
	
	return _rootListController;
}

@end
