//
//  HBNTTableViewCell.m
//  NewTerm
//
//  Created by Adam D on 21/07/2014.
//  Copyright (c) 2014 HASHBANG Productions. All rights reserved.
//

#import "HBNTTableViewCell.h"

@implementation HBNTTableViewCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
	self = [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
	return self;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	
	if (self) {
		[self _commonSetup];
	}
	
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	
	if (self) {
		[self _commonSetup];
	}
	
	return self;
}

- (void)_commonSetup {
	self.textLabel.textColor = [UIColor whiteColor];
	self.detailTextLabel.textColor = [UIColor whiteColor];
	self.selectedBackgroundView = [[UIView alloc] init];
	self.selectedBackgroundView.backgroundColor = [UITableView appearance].separatorColor;
}

@end
