// TerminalKeyboard.m
// MobileTerminal

#import "TerminalKeyboard.h"


@interface InputHandler : NSObject <UITextFieldDelegate>
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
  [textField setText:@" "];
  return NO;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
  if (action == @selector(copy:)) {
    // Only show the copy menu if we actually have any data selected
    NSMutableData* data = [NSMutableData  dataWithCapacity:0];
    [[terminalKeyboard inputDelegate] fillDataWithSelection:data];
    return [data length] > 0;
  }
  if (action == @selector(paste:)) {
    // Only paste if the board contains plain text
    return [[UIPasteboard generalPasteboard] containsPasteboardTypes:UIPasteboardTypeListString];
  }
  return NO;
}

- (void)copy:(id)sender
{
  NSMutableData* data = [NSMutableData  dataWithCapacity:0];
  [[terminalKeyboard inputDelegate] fillDataWithSelection:data];
  UIPasteboard* pb = [UIPasteboard generalPasteboard];
  pb.string = [[NSString alloc] initWithData:data 
                                    encoding:NSUTF8StringEncoding];
}

- (void)paste:(id)sender
{
  UIPasteboard* pb = [UIPasteboard generalPasteboard];
  if (![pb containsPasteboardTypes:UIPasteboardTypeListString]) {
    return;
  }
  NSData* data = [pb.string dataUsingEncoding:NSUTF8StringEncoding];
  [[terminalKeyboard inputDelegate] receiveKeyboardInput:data];
}

@end


@implementation TerminalKeyboard

@synthesize inputDelegate;

- (id)init
{
  self = [super init];
  if (self != nil) {
    [self setOpaque:YES];
    
    inputTextField = [[UITextField alloc] init];
    [inputTextField setKeyboardType:UIKeyboardTypeASCIICapable];
    [inputTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [inputTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [inputTextField setEnablesReturnKeyAutomatically:NO];
    
    // To intercept keyboard events we make this object its own delegate.  A
    // workaround to the fact that we don't get keyboard events for backspaces
    // in an empty text field is that we put some text in the box, but always
    // return NO from our delegate method so it is never changed.
    [inputTextField setText:@" "];
    [self addSubview:inputTextField];
    
    // Handles key presses and forward them back to us
    inputHandler = [[InputHandler alloc] initWithTerminalKeyboard:self];
    [inputTextField setDelegate:inputHandler];
  }
  return self;
}

- (void)drawRect:(CGRect)rect {
  // Nothing to see here
}

- (BOOL)becomeFirstResponder
{
  // XXX
  return [inputTextField becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
  return [inputTextField resignFirstResponder];
}
  
- (void)dealloc {
  [inputTextField release];
  [super dealloc];
}

@end
