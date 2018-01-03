//
//  HBNTTerminalSessionViewController.h
//  NewTerm
//
//  Created by Adam D on 12/12/2014.
//  Copyright (c) 2014 HASHBANG Productions. All rights reserved.
//

#import "VT100Types.h"
#import "HBNTTerminalController.h"

@class VT100ColorMap;

@interface HBNTTerminalSessionViewController : UIViewController <HBNTTerminalControllerDelegate>

@property (nonatomic, strong, readonly) UITextView *textView;
@property (nonatomic) UIEdgeInsets barInsets;

@end
