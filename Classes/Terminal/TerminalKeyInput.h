//
//  TerminalKeyInput.h
//  MobileTerminal
//
//  Created by Adam D on 13/10/13.
//
//

#import "UITextInputBase.h"

@class TerminalKeyboard;

static const int kControlCharacter = 0x2022;

// This text field is the first responder that intercepts keyboard events and
// copy and paste events.
@interface TerminalKeyInput : UITextInputBase

@property (nonatomic, retain) TerminalKeyboard *keyboard;

// Should the next character pressed be a control character?
@property (nonatomic) BOOL controlKeyMode;
@property (copy) void(^controlKeyChanged)();

// UIKeyInput
@property (nonatomic) UITextAutocapitalizationType autocapitalizationType;
@property (nonatomic) UITextAutocorrectionType autocorrectionType;
@property (nonatomic) BOOL enablesReturnKeyAutomatically;
@property (nonatomic) UIKeyboardAppearance keyboardAppearance;
@property (nonatomic) UIKeyboardType keyboardType;
@property (nonatomic) UIReturnKeyType returnKeyType;
@property (nonatomic, getter=isSecureTextEntry) BOOL secureTextEntry;
@property (nonatomic, retain) UIView *inputAccessoryView;

- (id)initWithKeyboard:(TerminalKeyboard *)theKeyboard;

@end
