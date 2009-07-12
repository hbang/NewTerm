// TerminalKeyboard.m
// MobileTerminal

#import "TerminalKeyboard.h"
#import <UIKit/UIKit.h>

// The InputHandler
//
@interface InputHandler : UITextField <UITextFieldDelegate>
{
@private
  TerminalKeyboard* terminalKeyboard;
  NSData* backspaceData;
}
- (id)initWithTerminalKeyboard:(TerminalKeyboard*)keyboard;
@end

@implementation InputHandler

- (id)initWithTerminalKeyboard:(TerminalKeyboard*)keyboard
{
  self = [super init];
  if (self != nil) {
    terminalKeyboard = keyboard;    
    [self setKeyboardType:UIKeyboardTypeASCIICapable];
    [self setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self setEnablesReturnKeyAutomatically:NO];

    // To intercept keyboard events we make this object its own delegate.  A
    // workaround to the fact that we don't get keyboard events for backspaces
    // in an empty text field is that we put some text in the box, but always
    // return NO from our delegate method so it is never changed.
    [self setText:@" "];
    [self setDelegate:self];
    
    // Data to send in response to a backspace.  This is created now so it is
    // not re-allocated on ever backspace event.
    backspaceData = [[NSData alloc] initWithBytes:"\x08" length:1];
  }
  return self;
}

- (void) dealloc
{
  [backspaceData release];
  [super dealloc];
}

  
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range 
                                                       replacementString:(NSString *)string
{
  // An empty replacement string means a backspace event
  NSData* data =
      ([string length] == 0) ? backspaceData
                             : [string dataUsingEncoding:NSUTF8StringEncoding];
  [[terminalKeyboard inputDelegate] receiveKeyboardInput:data];
  // Don't let the text get updated so never have to worry about not getting
  // a backspace event.  
  return NO;
}

@end


@implementation TerminalKeyboard

@synthesize inputDelegate;

- (id)init
{
  self = [super init];
  if (self != nil) {
    [self setOpaque:YES];
    
    // Handles key presses and forward them back to us
    inputHandler = [[InputHandler alloc] initWithTerminalKeyboard:self];
    [self addSubview:inputHandler];
  }
  return self;
}

- (void)drawRect:(CGRect)rect {
  // Nothing to see here
}

- (BOOL)becomeFirstResponder
{
  return [inputHandler becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
  return [inputHandler resignFirstResponder];
}
  
- (void)dealloc {
  [inputHandler release];
  [super dealloc];
}

@end
