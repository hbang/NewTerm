//
//  TerminalKeyInput.m
//  MobileTerminal
//
//  Created by Adam D on 13/10/13.
//
//

#import "TerminalKeyInput.h"
#import "TerminalKeyboard.h"

@interface TerminalKeyInput () {
	NSData *_backspaceData;
	// Should the next character pressed be a control character?
	BOOL _controlKeyMode;
	
	UITextAutocapitalizationType _autocapitalizationType;
	UITextAutocorrectionType _autocorrectionType;
	BOOL _enablesReturnKeyAutomatically;
	UIKeyboardAppearance _keyboardAppearance;
	UIKeyboardType _keyboardType;
	UIReturnKeyType _returnKeyType;
	BOOL _secureTextEntry;
}

@end

@implementation TerminalKeyInput

@synthesize autocapitalizationType = _autocapitalizationType, autocorrectionType = _autocorrectionType, enablesReturnKeyAutomatically = _enablesReturnKeyAutomatically, keyboardAppearance = _keyboardAppearance, keyboardType = _keyboardType, secureTextEntry = _secureTextEntry;

- (id)initWithKeyboard:(TerminalKeyboard *)theKeyboard {
	self = [super init];
	if (self != nil) {
		_keyboard = theKeyboard;
		_autocapitalizationType = UITextAutocapitalizationTypeNone;
		_autocorrectionType = UITextAutocorrectionTypeNo;
		_enablesReturnKeyAutomatically = NO;
		_keyboardAppearance = UIKeyboardAppearanceAlert;
		_keyboardType = UIKeyboardTypeASCIICapable;
		_returnKeyType = UIReturnKeyDefault;
		_secureTextEntry = NO;
		
		// Data to send in response to a backspace.	 This is created now so it is
		// not re-allocated on ever backspace event.
		_backspaceData = [[NSData alloc] initWithBytes:"\x7F" length:1];
		_controlKeyMode = FALSE;
	}
	return self;
}

- (void)deleteBackward {
	[[_keyboard inputDelegate] receiveKeyboardInput:_backspaceData];
}

- (BOOL)hasText
{
	// Make sure that the backspace key always works
	return YES;
}

- (void)insertText:(NSString *)input
{
	// First character is always space (that we set)
	unichar c = [input characterAtIndex:0];
	if (_controlKeyMode) {
		_controlKeyMode = NO;
		// Convert the character to a control key with the same ascii name (or
		// just use the original character if not in the acsii range)
		if (c < 0x60 && c > 0x40) {
			// Uppercase (and a few characters nearby, such as escape)
			c -= 0x40;
		} else if (c < 0x7B && c > 0x60) {
			// Lowercase
			c -= 0x60;
		}
	} else {
		if (c == kControlCharacter) {
			// Control character was pressed.	 The next character will be interpred
			// as a control key.
			_controlKeyMode = YES;
			return;
		} else if (c == 0x0a) {
			// Convert newline to a carraige return
			c = 0x0d;
		}
	}
	// Re-encode as UTF8
	NSString *encoded = [NSString stringWithCharacters:&c length:1];
	NSData *data = [encoded dataUsingEncoding:NSUTF8StringEncoding];
	[[_keyboard inputDelegate] receiveKeyboardInput:data];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
	if (action == @selector(copy:)) {
		// Only show the copy menu if we actually have any data selected
		NSMutableData *data = [NSMutableData	dataWithCapacity:0];
		[[_keyboard inputDelegate] fillDataWithSelection:data];
		return [data length] > 0;
	}
	if (action == @selector(paste:)) {
		// Only paste if the board contains plain text
		return [[UIPasteboard generalPasteboard] containsPasteboardTypes:UIPasteboardTypeListString];
	}
	return NO;
}

- (void)copy:(id)sender {
	NSMutableData *data = [NSMutableData	dataWithCapacity:0];
	[[_keyboard inputDelegate] fillDataWithSelection:data];
	UIPasteboard *pb = [UIPasteboard generalPasteboard];
	pb.string = [[[NSString alloc] initWithData:data
									   encoding:NSUTF8StringEncoding] autorelease];
}

- (void)paste:(id)sender {
	UIPasteboard *pb = [UIPasteboard generalPasteboard];
	if (![pb containsPasteboardTypes:UIPasteboardTypeListString]) {
		return;
	}
	NSData *data = [pb.string dataUsingEncoding:NSUTF8StringEncoding];
	[[_keyboard inputDelegate] receiveKeyboardInput:data];
}

- (BOOL)becomeFirstResponder {
	[super becomeFirstResponder];
	return YES;
}

- (BOOL)canBecomeFirstResponder {
	return YES;
}

@end
