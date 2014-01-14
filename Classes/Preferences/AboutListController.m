//
//  AboutListController.m
//  MobileTerminal
//
//  Created by Adam D on 15/01/2014.
//
//

#import "AboutListController.h"

@interface AboutListController ()

@end

@implementation AboutListController

#pragma mark - PSListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"About" target:self] retain];
	}
	
	return _specifiers;
}

#pragma mark - Callbacks

- (void)openGitHubIssues {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/hbang/NewTerm/issues"]];
}

@end
