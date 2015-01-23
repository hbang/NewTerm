//
//  HBNTKeyInput.m
//  NewTerm
//
//  Created by Adam D on 23/01/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

#import "HBNTTerminalKeyInput.h"
#import "HBNTTerminalKeyInputDelegate.h"
#import "HBNTTerminalKeyboard.h"

@implementation HBNTTerminalKeyInput {
	HBNTTerminalModifierKey _currentModifierKey;
}

- (instancetype)initWithKeyboard:(HBNTTerminalKeyboard *)keyboard delegate:(id<HBNTTerminalKeyInputDelegate>)delegate {
	self = [super init];
	
	if (self) {
		_keyboard = keyboard;
		_delegate = delegate;
	}
	
	return self;
}

- (BOOL)hasText {
	return YES;
}

- (void)insertText:(NSString *)input {
	// First character is always space (that we set)
	unichar character = [input characterAtIndex:0];
	
	if (_currentModifierKey != HBNTTerminalModifierKeyNone) {
		// TODO: currently only supporting ctrl
		
		// Convert the character to a control key with the same ascii name (or
		// just use the original character if not in the acsii range)
		if (character < 0x60 && character > 0x40) {
			// Uppercase (and a few characters nearby, such as escape)
			character -= 0x40;
		} else if (character < 0x7B && character > 0x60) {
			// Lowercase
			character -= 0x60;
		}
		
		if (_delegate) {
			[_delegate terminalModifierKeyReleased:_currentModifierKey];
		}
		
		_currentModifierKey = HBNTTerminalModifierKeyNone;
	} else {
		if (character == 0x0a) {
			// Convert newline to a carraige return
			character = 0x0d;
		}
	}
	
	// Re-encode as UTF8
	NSString *encoded = [NSString stringWithCharacters:&character length:1];
	NSData *data = [encoded dataUsingEncoding:NSUTF8StringEncoding];
	[_keyboard.inputDelegate receiveKeyboardInput:data];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	if (action == @selector(copy:)) {
		// Only show the copy menu if we actually have any data selected
		NSMutableData *data = [NSMutableData dataWithCapacity:0];
		[_keyboard.inputDelegate fillDataWithSelection:data];
		return data.length > 0;
	} else if (action == @selector(paste:)) {
		// Only paste if the board contains plain text
		return [[UIPasteboard generalPasteboard] containsPasteboardTypes:UIPasteboardTypeListString];
	}
	
	return NO;
}

- (void)copy:(id)sender {
	NSMutableData *data = [NSMutableData dataWithCapacity:0];
	[_keyboard.inputDelegate fillDataWithSelection:data];
	
	[UIPasteboard generalPasteboard].string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (void)paste:(id)sender {
	UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
	
	if (![pasteboard containsPasteboardTypes:UIPasteboardTypeListString]) {
		return;
	}
	
	NSData *data = [pasteboard.string dataUsingEncoding:NSUTF8StringEncoding];
	[_keyboard.inputDelegate receiveKeyboardInput:data];
}

- (BOOL)becomeFirstResponder {
	[super becomeFirstResponder];
	return YES;
}

- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (void)pressModifierKey:(HBNTTerminalModifierKey)key {
	// TODO
}

@end
