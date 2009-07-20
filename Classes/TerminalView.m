// TerminalView.m
// MobileTerminal

#import "TerminalView.h"

#import "VT100/VT100TextView.h"
#import "SubProcess/SubProcess.h"

@implementation TerminalView

// Initializes the sub process and pty object.  This sets up a listener that
// invokes a callback when data from the subprocess is available.
- (void)initSubProcess
{
  stopped = NO;
  subProcess = [[SubProcess alloc] init];  
  [subProcess start];
  
  // The PTY will be sized correctly on the first call to layoutSubViews
  pty = [[PTY alloc] initWithFileHandle:[subProcess fileHandle]];
  
  // Schedule an async read of the subprocess.  Invokes our callback when
  // data becomes available.
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(dataAvailable:)
                                               name:NSFileHandleReadCompletionNotification
                                             object:[subProcess fileHandle]];
  [[subProcess fileHandle] readInBackgroundAndNotify];   
}

- (void)releaseSubProcess
{
  stopped = YES;
  [pty release];
  [subProcess stop];
  [subProcess release];
}

static const char* kProcessExitedMessage =
    "[Process completed]\r\n"
    "Press any key to restart.\r\n";

- (void)dataAvailable:(NSNotification *)aNotification {
  NSData* data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
  if ([data length] == 0) {
    // I would expect from the documentation that an EOF would be present as
    // an entry in the userinfo dictionary as @"NSFileHandleError", but that is
    // never present.  Instead, it seems to just appear as an empty data
    // message.  This usually happens when someone just types "exit".  Simply
    // restart the subprocess when this happens.
    
    // On EOF, either (a) the user typed "exit" or (b) the terminal never
    // started in first place due to a misconfiguration of the BSD subsystem
    // (can't find /bin/login, etc).  To allow the user to proceed in case (a),
    // display a message with instructions on how to restart the shell.  We
    // don't restart automatically in case of (b), which would put us in an
    // infinite loop.  Print a message on the screen with instructions on how
    // to restart the process.
    NSData* message = [NSData dataWithBytes:kProcessExitedMessage
                                     length:strlen(kProcessExitedMessage)];
    [textView readInputStream:message];
    [self releaseSubProcess];
    return;
  }
  
  // Forward the subprocess data into the terminal character handler
  [textView readInputStream:data];
  
  // Queue another read
  [[subProcess fileHandle] readInBackgroundAndNotify];
}

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super initWithCoder:decoder];
  if (self != nil) {
    textView = [[VT100TextView alloc] initWithCoder:decoder];
    [textView setFrame:self.frame];
    [self addSubview:textView];

    // Start the background terminal process
    [self initSubProcess];
  }
  return self;
}

- (void)dealloc {
  [self releaseSubProcess];
  [super dealloc];
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  // Send the terminal the actual size of our vt100 view.  This should be
  // called any time we change the size of the view.  This should be a no-op if
  // the size has not changed since the last time we called it.
  [pty setWidth:[textView width] withHeight:[textView height]];
}

- (void)receiveKeyboardInput:(NSData*)data
{
  if (stopped) {
    // The sub process previously exited, restart it at the users request.
    [textView clearScreen];
    [self initSubProcess];
  } else {
    // Forward the data from the keyboard directly to the subprocess
    [[subProcess fileHandle] writeData:data];
  }
}

- (void)setFont:(UIFont*)font
{
  [textView setFont:font];
}

- (UIFont*)font
{
  return [textView font];
}

- (ColorMap*)colorMap
{
  return [textView colorMap];
}


@end
