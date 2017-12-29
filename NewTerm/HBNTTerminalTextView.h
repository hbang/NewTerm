//
//  HBNTTerminalTextView.h
//  NewTerm
//
//  Created by Adam D on 26/01/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

typedef NS_ENUM(NSUInteger, HBNTTerminalModifierKey) {
	HBNTTerminalModifierKeyNone,
	HBNTTerminalModifierKeyCtrl,
	HBNTTerminalModifierKeyMeta,
	HBNTTerminalModifierKeyEsc
};

typedef void (^HBNTTerminalKeyUpCompletion)();

// Protocol implemented by listener of keyboard events
@protocol HBNTTerminalInputProtocol

@required
- (void)receiveKeyboardInput:(NSData *)data;

@end

@protocol HBNTTerminalKeyboardProtocol <HBNTTerminalInputProtocol>

@required
- (void)modifierKeyPressed:(HBNTTerminalModifierKey)modifierKey;

@end

@interface HBNTTerminalTextView : UITextView

@property (strong, nonatomic) id<HBNTTerminalKeyboardProtocol> terminalInputDelegate;

@end
