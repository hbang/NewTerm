//
//  HBNTPreferencesListItemsController.m
//  NewTerm
//
//  Created by Adam Demasi on 19/4/20.
//  Copyright © 2020 HASHBANG Productions. All rights reserved.
//

#import "HBNTPreferencesListItemsController.h"

@implementation HBNTPreferencesListItemsController

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[super tableView:tableView didSelectRowAtIndexPath:indexPath];
	[self.navigationController popViewControllerAnimated:YES];
}

@end
