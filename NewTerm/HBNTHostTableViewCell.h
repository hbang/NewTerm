//
//  HBNTHostTableViewCell.h
//  NewTerm
//
//  Created by Adam D on 21/07/2014.
//  Copyright (c) 2014 HASHBANG Productions. All rights reserved.
//

#import "HBNTTextFieldTableViewCell.h"
#import "HBNTTextField.h"

@interface HBNTHostTableViewCell : HBNTTextFieldTableViewCell <UITextFieldDelegate>

@property (strong, nonatomic) HBNTTextField *portTextField;

@end
