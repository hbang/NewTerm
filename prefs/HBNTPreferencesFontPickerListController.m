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
		UIFontDescriptor *descriptor = [[UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody] fontDescriptorWithDesign:UIFontDescriptorSystemDesignMonospaced];
		font = [UIFont fontWithDescriptor:descriptor size:pointSize];
	} else {
		font = [UIFont fontWithName:_fonts[identifier][@"Regular"] size:pointSize];
	}
	cell.textLabel.font = font;

	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	PSTableCell *cell = (PSTableCell *)[tableView cellForRowAtIndexPath:indexPath];
	NSString *identifier = cell.specifier.identifier;

	// Check if this font can be used. Tell the user why if it can’t be used, and ensure we don’t set
	// it.
	if ([UIFont fontWithName:_fonts[identifier][@"Regular"] size:12] == nil) {
		NSBundle *bundle = [NSBundle bundleForClass:self.class];
		NSString *title = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"INSTALL_FONTS_TITLE", @"Localizable", bundle, @"Message displayed when a font isn’t installed, directing the user to install it."), cell.textLabel.text];
		NSString *ok = NSLocalizedStringFromTableInBundle(@"INSTALL", @"Localizable", bundle, @"Button displayed under the above title, to install the font.");
		NSString *cancel = NSLocalizedStringFromTableInBundle(@"Cancel", @"Localizable", [NSBundle bundleForClass:UIView.class], @"");
		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
		[alertController addAction:[UIAlertAction actionWithTitle:ok style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://chariz.com/get/newterm-fonts"] options:@{} completionHandler:nil];
		}]];
		[alertController addAction:[UIAlertAction actionWithTitle:cancel style:UIAlertActionStyleCancel handler:nil]];
		[self presentViewController:alertController animated:YES completion:nil];
		[tableView deselectRowAtIndexPath:indexPath animated:YES];
		return;
	}

	[super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

@end
