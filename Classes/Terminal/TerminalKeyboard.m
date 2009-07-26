// TerminalKeyboard.m
// MobileTerminal

#import "TerminalKeyboard.h"

// The InputHandler
//
@interface InputHandler : UITextField <UITextFieldDelegate>
{
@private
  TerminalKeyboard* terminalKeyboard;
  NSData* backspaceData;
  
  // Should the next character pressed be a control character?
  BOOL controlKeyMode;
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

    controlKeyMode = FALSE;
  }
  return self;
}

- (void) dealloc
{
  [backspaceData release];
  [super dealloc];
}

// This is the key that looks like a dot.  When pressed, the next character is
// treated as a control character (ie, press dot then C to get control-C).
static const int kControlCharacter = 0x2022;
  
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range 
                                                       replacementString:(NSString *)string
{

  NSData* data;
  if ([string length] == 0) {
    // An empty replacement string means the backspace key was pressed
    data = backspaceData;
  } else {
    unichar c = [string characterAtIndex:0];
    if (controlKeyMode) {
      controlKeyMode = NO;
      // Convert the character to a control key with the same ascii name (or
      // just use the original character if not in the acsii range)
      // was in ctrl key mode, got another key
      if (c < 0x60 && c > 0x40) {
        // Uppercase (and a few characters nearby, such as escape)
        c -= 0x40;
      } else if (c < 0x7B && c > 0x60) {
        // Lowercase
        c -= 0x60;
      }
    } else {
      if (c == kControlCharacter) {
        // Control character was pressed.  The next character will be interpred
        // as a control key.
        controlKeyMode = YES;
        return NO;
      } else if (c == 0x0a) {
        // Convert newline to a carraige return
        c = 0x0d;
      }
    }
    // Re-encode as UTF8
    NSString* encoded = [NSString stringWithCharacters:&c length:1];
    data = [encoded dataUsingEncoding:NSUTF8StringEncoding];
  }
  [[terminalKeyboard inputDelegate] receiveKeyboardInput:data];
  // Don't let the text get updated so never have to worry about not getting
  // a backspace event.  
  return NO;
}

- (void)keyboardInputChanged:(id)sender
{
  // This is a workaround for a bug either in this code or in the official 3.0
  // SDK.  Without this overridden method, we get in an infinite loop when
  // this text field becomes the first responder.
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
