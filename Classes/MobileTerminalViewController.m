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

- (void)keyboardWasShown:(NSNotification*)aNotification
{
  if (keyboardShown)
    return;
  
  NSDictionary* info = [aNotification userInfo];
  
  // Get the size of the keyboard.
  NSValue* aValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
  CGSize keyboardSize = [aValue CGRectValue].size;
  
  // Resize the scroll view (which is the root view of the window)
  CGRect viewFrame = [[self view] frame];
  viewFrame.size.height -= keyboardSize.height;
  [self view].frame = viewFrame;
  
  keyboardShown = YES;
}

// TODO(allen): This doesn't do the right thing when rotating in the simulator
- (void)keyboardWasHidden:(NSNotification*)aNotification
{
  if (!keyboardShown)
    return;
  
  NSDictionary* info = [aNotification userInfo];
  
  // Get the size of the keyboard.
  NSValue* aValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
  CGSize keyboardSize = [aValue CGRectValue].size;
  
  // Reset the height of the scroll view to its original value
  CGRect viewFrame = [[self view] frame];
  viewFrame.size.height += keyboardSize.height;
  [self view].frame = viewFrame;
  
  keyboardShown = NO;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  vt100TextView.font = [UIFont fontWithName:@"Courier" size:10.0f];

  
  // Adding the keyboard to the view has no effect, except that it is will
  // later allow us to make it the first responder so we can show the keyboard
  // on the screen.
  [[self view] addSubview:terminalKeyboard];

  [self registerForKeyboardNotifications];
  
  // Show the keyboard
  // TODO(allen): This should hook in with preferences
  [terminalKeyboard becomeFirstResponder];

  // Prepare subprocess stuff
  [subProcess start];
  
  // Resize the PTY based on the font size of the text view
  pty = [[PTY alloc] initWithFileHandle:[subProcess fileHandle]];
  [pty setWidth:[vt100TextView width] withHeight:[vt100TextView height]];
  
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
