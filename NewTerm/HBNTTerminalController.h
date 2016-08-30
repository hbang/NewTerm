//
//  HBNTTerminalController.h
//  NewTerm
//
//  Created by Adam D on 22/01/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

#import "HBNTTerminalTextView.h"

@class HBNTTerminalSessionViewController, VT100ColorMap;

@interface HBNTTerminalController : NSObject <HBNTTerminalKeyboardProtocol>

- (void)startSubProcess;
- (void)updateScreenSize;

@property (strong, nonatomic) HBNTTerminalSessionViewController *viewController;
@property (strong, nonatomic) UIFont *font;
@property (strong, nonatomic) VT100ColorMap *colorMap;

@end
