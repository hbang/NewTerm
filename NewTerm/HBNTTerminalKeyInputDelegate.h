//
//  HBNTTerminalKeyInputDelegate.h
//  NewTerm
//
//  Created by Adam D on 23/01/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HBNTTerminalKeyInput.h"

@protocol HBNTTerminalKeyInputDelegate <NSObject>

@required
- (void)terminalModifierKeyReleased:(HBNTTerminalModifierKey)key;

@end
