//
//  HBNTTerminalKeyboard.m
//  NewTerm
//
//  Created by Adam D on 23/01/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

#import "HBNTTerminalKeyboard.h"
#import "HBNTTerminalKeyInput.h"

@implementation HBNTTerminalKeyboard

- (instancetype)init {
	self = [super init];
	
	if (self) {
		self.opaque = YES;
		
		_inputTextField = [[HBNTTerminalKeyInput alloc] initWithKeyboard:self delegate:self];
		[self addSubview:_inputTextField];
	}
	
	return self;
}

- (void)drawRect:(CGRect)rect {
	// Nothing to see here
}

- (BOOL)becomeFirstResponder {
	return [_inputTextField becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
	return [_inputTextField resignFirstResponder];
}

#pragma mark - HBNTTerminalKeyInputDelegate

- (void)terminalModifierKeyReleased:(HBNTTerminalModifierKey)key {
	// TODO
}

@end
