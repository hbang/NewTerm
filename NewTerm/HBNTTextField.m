//
//  HBNTTextField.m
//  NewTerm
//
//  Created by Adam D on 21/07/2014.
//  Copyright (c) 2014 HASHBANG Productions. All rights reserved.
//

#import "HBNTTextField.h"

@implementation HBNTTextField

- (NSString *)placeholder {
	return self.attributedPlaceholder.string;
}

- (void)setPlaceholder:(NSString *)placeholder {
	self.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder attributes:@{ NSForegroundColorAttributeName: [UITableView appearance].separatorColor }];
}

@end
