// MobileTerminalViewController.m
// MobileTerminal

#import "MobileTerminalViewController.h"

#import <VT100/VT100TextView.h>
#import <SubProcess/SubProcess.h>
#import "TerminalKeyboard.h"

@implementation MobileTerminalViewController

@synthesize vt100TextView;

- (void)dataAvailable:(NSNotification *)aNotification {
  // Forward the subprocess data into the terminal character handler
  NSData* data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
  [vt100TextView readInputStream:data];
  
  // Queue another read
  [[subProcess fileHandle] readInBackgroundAndNotify];
}

// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super initWithCoder:decoder];
  if (self != nil) {
    subProcess = [[SubProcess alloc] init];
    pty = NULL;
    terminalKeyboard = [[TerminalKeyboard alloc] init];
    terminalKeyboard.inputDelegate = self;
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

// Send the terminal the actual size of our vt100 view.  This should be
// called any time we change the size of the view.  This should be a no-op if
// the size has not changed since the last time we called it.
- (void)refreshPtySize
{
  [pty setWidth:[vt100TextView width] withHeight:[vt100TextView height]];
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
  CGRect viewFrame = [vt100TextView frame];
  viewFrame.size.height -= keyboardSize.height;
  vt100TextView.frame = viewFrame;
  
  // Let the subprocess know that the screen size has changed
  [self refreshPtySize];
}

// TODO(allen): This doesn't do the right thing when rotating in the simulator
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
  CGRect viewFrame = [vt100TextView frame];
  viewFrame.size.height += keyboardSize.height;
  vt100TextView.frame = viewFrame;

  // Let the subprocess know that the screen size has changed
  [self refreshPtySize];
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
  // TODO(allen): This should be configurable
  [vt100TextView setFont:[UIFont fontWithName:@"Courier" size:10.0f]];
  
  // Prepare subprocess stuff
  [subProcess start];
  
  // Resize the PTY based on the font size of the text view
  pty = [[PTY alloc] initWithFileHandle:[subProcess fileHandle]];
  [self refreshPtySize];
  
  // Schedule an async read of the subprocess.  Invokes our callback when
  // data becomes available.
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(dataAvailable:)
                                               name:NSFileHandleReadCompletionNotification
                                             object:[subProcess fileHandle]];
  [[subProcess fileHandle] readInBackgroundAndNotify];  
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
  // Also let the terminal subprocess know about the new window size.
  [self refreshPtySize];
}

- (void)didReceiveMemoryWarning {
	// TODO(allen): Should clear scrollback buffers to save memory? 
  [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
  [subProcess stop];
  [pty dealloc];
  pty = NULL;
}

- (void)dealloc {
  [subProcess dealloc];
  [super dealloc];
}

- (void)receiveKeyboardInput:(NSData*)data
{
  // Forward the data from the keyboard directly to the subprocess
  [[subProcess fileHandle] writeData:data];
}

@end
