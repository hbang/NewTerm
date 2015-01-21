//
//  HBNTTableViewCell.h
//  NewTerm
//
//  Created by Adam D on 21/07/2014.
//  Copyright (c) 2014 HASHBANG Productions. All rights reserved.
//

#import <UIKit/UIKit.h>

static CGFloat const kHBNTTableViewCellMargin = 15.f;

@interface HBNTTableViewCell : UITableViewCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier;

@end
