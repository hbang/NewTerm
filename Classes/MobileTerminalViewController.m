// MobileTerminalViewController.m
// MobileTerminal

#import "MobileTerminalViewController.h"

#import "VT100/ColorMap.h"
#import "TerminalKeyboard.h"
#import "TerminalGroupView.h"
#import "TerminalView.h"

@implementation MobileTerminalViewController

@synthesize contentView;
@synthesize terminalGroupView;
@synthesize terminalSelector;

// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super initWithCoder:decoder];
  if (self != nil) {
    terminalKeyboard = [[TerminalKeyboard alloc] init];
    keyboardShown = NO;    
  }
  return self;
}

- (void)registerForKeyboardNotifications
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWasShown:)
                                               name:UIKeyboardDidShowNotification object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(keyboardWasHidden:)
                                               name:UIKeyboardDidHideNotification object:nil];
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
  if (keyboardShown)
    return;
  keyboardShown = YES;

  NSDictionary* info = [aNotification userInfo];
  
  // Get the size of the keyboard.
  NSValue* aValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
  CGSize keyboardSize = [aValue CGRectValue].size;
  
  // Reset the height of the terminal to full screen not shown by the keyboard
  CGRect viewFrame = [contentView frame];
  viewFrame.size.height -= keyboardSize.height;
  contentView.frame = viewFrame;
}

- (void)keyboardWasHidden:(NSNotification*)aNotification
{
  if (!keyboardShown)
    return;
  keyboardShown = NO;
  
  NSDictionary* info = [aNotification userInfo];
  
  // Get the size of the keyboard.
  NSValue* aValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
  CGSize keyboardSize = [aValue CGRectValue].size;  
  
  // Resize to the original height of the screen without the keyboard
  CGRect viewFrame = [contentView frame];
  viewFrame.size.height += keyboardSize.height;
  contentView.frame = viewFrame;
}

- (void)terminalSelectionDidChange:(id)sender 
{
  TerminalView* terminalView =
      [terminalGroupView terminalAtIndex:[terminalSelector currentPage]];
  terminalKeyboard.inputDelegate = terminalView;
  [terminalGroupView bringTerminalToFront:terminalView];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  // Adding the keyboard to the view has no effect, except that it is will
  // later allow us to make it the first responder so we can show the keyboard
  // on the screen.
  [[self view] addSubview:terminalKeyboard];
  [self registerForKeyboardNotifications];
  
  // Show the keyboard
  // TODO(allen):  This should be configurable
  [terminalKeyboard becomeFirstResponder];
  
  [terminalSelector setNumberOfPages:[terminalGroupView terminalCount]];
  [terminalSelector setCurrentPage:0];
  [terminalSelector addTarget:self
                       action:@selector(terminalSelectionDidChange:)
             forControlEvents:UIControlEventTouchUpInside];
  // Select the first terminal
  [self terminalSelectionDidChange:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  // This supports everything except for upside down, since upside down is most
  // likely accidental.
  switch (interfaceOrientation) {
    case UIInterfaceOrientationPortrait:
    case UIInterfaceOrientationLandscapeLeft:
    case UIInterfaceOrientationLandscapeRight:
      return YES;
    default:
      return NO;
  }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{  
  // We rotated, and almost certainly changed the frame size of the text view.
  [[self view] layoutSubviews];
}

- (void)didReceiveMemoryWarning {
	// TODO(allen): Should clear scrollback buffers to save memory? 
  [super didReceiveMemoryWarning];
}

- (void)dealloc {
  [terminalKeyboard release];
  [super dealloc];
}


@end
