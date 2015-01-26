//
//  HBNTTerminalTextView.m
//  NewTerm
//
//  Created by Adam D on 26/01/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

#import "HBNTTerminalTextView.h"

@implementation HBNTTerminalTextView {
	HBNTTerminalModifierKey _currentModifierKey;
}

- (void)pressModifierKey:(HBNTTerminalModifierKey)key {
	// TODO
}

#pragma mark - UITextInput

- (BOOL)hasText {
	return YES;
}

- (void)insertText:(NSString *)input {
	NSMutableData *data = [NSMutableData data];
	
	for (NSUInteger i = 0; i < input.length; i++) {
		unichar character = [input characterAtIndex:i];
		
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
			
			[_terminalInputDelegate modifierKeyPressed:_currentModifierKey];
			
			_currentModifierKey = HBNTTerminalModifierKeyNone;
		} else {
			if (character == 0x0a) {
				// Convert newline to a carraige return
				character = 0x0d;
			}
		}
		
		// Re-encode as UTF8
		[data appendBytes:&character length:1];
	}
	
	[_terminalInputDelegate receiveKeyboardInput:data];
}

- (void)deleteBackward {
	static NSData *BackspaceData;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		BackspaceData = [[NSData alloc] initWithBytes:"\x7F" length:1];
	});
	
	[_terminalInputDelegate receiveKeyboardInput:BackspaceData];
}

#pragma mark - UIResponder

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	if (action == @selector(copy:)) {
		// Only show the copy menu if we actually have any data selected
		NSMutableData *data = [NSMutableData dataWithCapacity:0];
		[_terminalInputDelegate fillDataWithSelection:data];
		return data.length > 0;
	} else if (action == @selector(paste:)) {
		// Only paste if the board contains plain text
		return [[UIPasteboard generalPasteboard] containsPasteboardTypes:UIPasteboardTypeListString];
	}
	
	return NO;
}

- (void)copy:(id)sender {
	NSMutableData *data = [NSMutableData dataWithCapacity:0];
	[_terminalInputDelegate fillDataWithSelection:data];
	
	[UIPasteboard generalPasteboard].string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (void)paste:(id)sender {
	UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
	
	if (![pasteboard containsPasteboardTypes:UIPasteboardTypeListString]) {
		return;
	}
	
	[_terminalInputDelegate receiveKeyboardInput:[pasteboard.string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (BOOL)becomeFirstResponder {
	[super becomeFirstResponder];
	return YES;
}

- (BOOL)canBecomeFirstResponder {
	return YES;
}

@end
