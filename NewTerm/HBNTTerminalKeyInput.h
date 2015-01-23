//
//  HBNTKeyInput.h
//  NewTerm
//
//  Created by Adam D on 23/01/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

#import "HBNTTextInputBase.h"

typedef NS_ENUM(NSUInteger, HBNTTerminalModifierKey) {
	HBNTTerminalModifierKeyNone,
	HBNTTerminalModifierKeyCtrl,
	HBNTTerminalModifierKeyMeta,
	HBNTTerminalModifierKeyEsc
};

typedef void(^HBNTTerminalKeyUpCompletion)();

@class HBNTTerminalKeyboard;
@protocol HBNTTerminalKeyInputDelegate;

@interface HBNTTerminalKeyInput : HBNTTextInputBase

- (instancetype)initWithKeyboard:(HBNTTerminalKeyboard *)keyboard delegate:(id<HBNTTerminalKeyInputDelegate>)delegate;

- (void)pressModifierKey:(HBNTTerminalModifierKey)key;

@property (strong, nonatomic) HBNTTerminalKeyboard *keyboard;
@property (strong, nonatomic) id<HBNTTerminalKeyInputDelegate> delegate;

@end
