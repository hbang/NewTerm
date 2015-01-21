//
//  HBNTTextFieldTableViewCell.m
//  NewTerm
//
//  Created by Adam D on 21/07/2014.
//  Copyright (c) 2014 HASHBANG Productions. All rights reserved.
//

#import "HBNTTextFieldTableViewCell.h"

static CGFloat const kHBNTTextFieldTableViewCellLabelWidth = 85.f;

@implementation HBNTTextFieldTableViewCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithReuseIdentifier:reuseIdentifier];
	
	if (self) {
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		
		CGFloat origin = kHBNTTableViewCellMargin + kHBNTTextFieldTableViewCellLabelWidth + kHBNTTableViewCellMargin;
		_textField = [[HBNTTextField alloc] initWithFrame:CGRectMake(origin, 0, self.contentView.frame.size.width - origin - kHBNTTableViewCellMargin, self.contentView.frame.size.height)];
		_textField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self.contentView addSubview:_textField];
	}
	
	return self;
}

@end
