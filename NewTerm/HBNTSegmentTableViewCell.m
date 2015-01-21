//
//  HBNTSegmentTableViewCell.m
//  NewTerm
//
//  Created by Adam D on 21/07/2014.
//  Copyright (c) 2014 HASHBANG Productions. All rights reserved.
//

#import "HBNTSegmentTableViewCell.h"

static CGFloat const kHBNTSegmentTableViewCellMarginY = 7.f;

@implementation HBNTSegmentTableViewCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithReuseIdentifier:reuseIdentifier];
	
	if (self) {
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		
		_segmentControl = [[UISegmentedControl alloc] initWithFrame:CGRectInset(self.contentView.frame, kHBNTTableViewCellMargin, kHBNTSegmentTableViewCellMarginY)];
		_segmentControl.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self.contentView addSubview:_segmentControl];
	}
	
	return self;
}

- (void)prepareForReuse {
	[super prepareForReuse];
	[_segmentControl removeAllSegments];
}

@end
