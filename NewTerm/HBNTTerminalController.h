//
//  HBNTTerminalController.h
//  NewTerm
//
//  Created by Adam D on 22/01/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HBNTTerminalSessionViewController, ColorMap;

@interface HBNTTerminalController : NSObject

- (void)startSubProcess;

@property (strong, nonatomic) HBNTTerminalSessionViewController *viewController;
@property (strong, nonatomic) UIFont *font;
@property (strong, nonatomic) ColorMap *colorMap;

@end
