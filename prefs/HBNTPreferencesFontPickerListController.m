//
//  HBNTPreferencesFontPickerListController.m
//  NewTerm
//
//  Created by Adam Demasi on 11/4/20.
//  Copyright © 2020 HASHBANG Productions. All rights reserved.
//

#import "HBNTPreferencesFontPickerListController.h"
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTableCell.h>
#import <dlfcn.h>

@implementation HBNTPreferencesFontPickerListController {
	NSDictionary <NSString *, NSDictionary <NSString *, NSString *> *> *_fonts;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	_fonts = [NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Fonts" withExtension:@"plist"]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	PSTableCell *cell = (PSTableCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];

	NSString *identifier = cell.specifier.identifier;
	UIFont *font = nil;
	CGFloat pointSize = cell.textLabel.font.pointSize;
	if ([identifier isEqualToString:@"SF Mono"]) {
		if (@available(iOS 13, *)) {
			// I’m using the latest SDK. Why can’t I link this?
			UIFontDescriptorSystemDesign *myUIFontDescriptorSystemDesignMonospaced = (UIFontDescriptorSystemDesign *)dlsym(RTLD_DEFAULT, "UIFontDescriptorSystemDesignMonospaced");
			UIFontDescriptor *descriptor = [[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody] fontDescriptorWithDesign:*myUIFontDescriptorSystemDesignMonospaced];
			font = [UIFont fontWithDescriptor:descriptor size:pointSize];
		}
	} else {
		font = [UIFont fontWithName:_fonts[identifier][@"Regular"] size:pointSize];
		if (font == nil) {
			// TODO: Needs to be installed
		}
	}
	cell.textLabel.font = font;

	return cell;
}

@end
