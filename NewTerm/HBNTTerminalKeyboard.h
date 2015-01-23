//
//  HBNTTerminalKeyboard.h
//  NewTerm
//
//  Created by Adam D on 23/01/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HBNTTerminalKeyInputDelegate.h"

// Protocol implemented by listener of keyboard events
@protocol HBNTTerminalInputProtocol

@required
- (void)receiveKeyboardInput:(NSData *)data;

@end

@protocol HBNTTerminalKeyboardProtocol <HBNTTerminalInputProtocol>

@required
- (void)fillDataWithSelection:(NSMutableData *)data;

@end

// The terminal keyboard. This is an opaque view that triggers rendering of the
// keyboard on the screen -- the keyboard is not rendered in this view itself.
// There is typically only ever one instance of TerminalKeyboard.
@interface HBNTTerminalKeyboard : UIView <HBNTTerminalKeyInputDelegate>

@property (strong, nonatomic) id<HBNTTerminalKeyboardProtocol> inputDelegate;
@property (strong, nonatomic) UIView <UITextInput>* inputTextField;

// Show and hide the keyboard, respectively. allers can listen to system
// keyboard notifications to get notified when the keyboard is shown.
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;

@end
