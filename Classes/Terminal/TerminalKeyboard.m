// TerminalKeyboard.m
// MobileTerminal

#import "TerminalKeyboard.h"
#import "UITextInputBase.h"

static const int kControlCharacter = 0x2022;

// This text field is the first responder that intercepts keyboard events and
// copy and paste events.
@interface TerminalKeyInput : UITextInputBase
{
@private
  TerminalKeyboard* keyboard;  
  NSData* backspaceData;
  // Should the next character pressed be a control character?
  BOOL controlKeyMode;  

  // UIKeyInput
  UITextAutocapitalizationType autocapitalizationType;
  UITextAutocorrectionType autocorrectionType;
  BOOL enablesReturnKeyAutomatically;
  UIKeyboardAppearance keyboardAppearance;
  UIKeyboardType keyboardType;
  UIReturnKeyType returnKeyType;
  BOOL secureTextEntry;
}

@property (nonatomic, retain) TerminalKeyboard* keyboard;

// UIKeyInput
@property (nonatomic) UITextAutocapitalizationType autocapitalizationType;
@property (nonatomic) UITextAutocorrectionType autocorrectionType;
@property (nonatomic) BOOL enablesReturnKeyAutomatically;
@property (nonatomic) UIKeyboardAppearance keyboardAppearance;
@property (nonatomic) UIKeyboardType keyboardType;
@property (nonatomic) UIReturnKeyType returnKeyType;
@property (nonatomic, getter=isSecureTextEntry) BOOL secureTextEntry;
@end

@implementation TerminalKeyInput

@synthesize keyboard;
@synthesize autocapitalizationType;
@synthesize autocorrectionType;
@synthesize enablesReturnKeyAutomatically;
@synthesize keyboardAppearance;
@synthesize keyboardType;
@synthesize returnKeyType;
@synthesize secureTextEntry;

- (id)init:(TerminalKeyboard*)theKeyboard
{
  self = [super init];
  if (self != nil) {
    keyboard = theKeyboard;
    [self setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    [self setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self setEnablesReturnKeyAutomatically:NO];
    [self setKeyboardAppearance:UIKeyboardAppearanceDefault];
    [self setKeyboardType:UIKeyboardTypeASCIICapable];
    [self setReturnKeyType:UIReturnKeyDefault];
    [self setSecureTextEntry:NO];

    // Data to send in response to a backspace.  This is created now so it is
    // not re-allocated on ever backspace event.
    backspaceData = [[NSData alloc] initWithBytes:"\x7F" length:1];    
    controlKeyMode = FALSE;
  }
  return self;
}

- (void)deleteBackward
{
  [[keyboard inputDelegate] receiveKeyboardInput:backspaceData];
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
      return;
    } else if (c == 0x0a) {
      // Convert newline to a carraige return
      c = 0x0d;
    }
  }    
  // Re-encode as UTF8
  NSString* encoded = [NSString stringWithCharacters:&c length:1];
  NSData* data = [encoded dataUsingEncoding:NSUTF8StringEncoding];
  [[keyboard inputDelegate] receiveKeyboardInput:data];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
  if (action == @selector(copy:)) {
    // Only show the copy menu if we actually have any data selected
    NSMutableData* data = [NSMutableData  dataWithCapacity:0];
    [[keyboard inputDelegate] fillDataWithSelection:data];
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
  [[keyboard inputDelegate] fillDataWithSelection:data];
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
  [[keyboard inputDelegate] receiveKeyboardInput:data];
}

- (BOOL)becomeFirstResponder
{
  [super becomeFirstResponder];
  return YES;
}

- (BOOL)canBecomeFirstResponder
{
  return YES;
}

@end


@implementation TerminalKeyboard

@synthesize inputDelegate;

- (id)init
{
  self = [super init];
  if (self != nil) {
    [self setOpaque:YES];  
    inputTextField = [[TerminalKeyInput alloc] init:self];
    [self addSubview:inputTextField];
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
