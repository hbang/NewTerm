// TerminalView.m
// MobileTerminal

#import "TerminalView.h"

#import "VT100/VT100TextView.h"
#import "SubProcess/SubProcess.h"

@implementation TerminalView

// Initializes the sub process and pty object.  This sets up a listener that
// invokes a callback when data from the subprocess is available.
- (void)startSubProcess
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
  if (subProcess == nil) {
    return;
  }
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
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
    subProcess = nil;
    copyAndPasteEnabled = NO;
    textView = [[VT100TextView alloc] initWithCoder:decoder];
    [textView setFrame:self.frame];
    [self addSubview:textView];
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
  // Make sure that the text view is laid out, which re-computes the terminal
  // size in rows and columns.
  [textView layoutSubviews];

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
    [self startSubProcess];
  } else {
    // Forward the data from the keyboard directly to the subprocess
    [[subProcess fileHandle] writeData:data];
  }
}

- (void)fillDataWithSelection:(NSMutableData*)data;
{
  return [textView fillDataWithSelection:data];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesBegan:touches withEvent:event];
  if (!copyAndPasteEnabled) {
    return;
  }  
  if ([textView hasSelection]) {
    [textView clearSelection];
  } else {
    UITouch *theTouch = [touches anyObject];
    CGPoint point = [theTouch locationInView:self];
    [textView setSelectionStart:point];
    [textView setSelectionEnd:point];
  }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
  [super touchesMoved:touches withEvent:event];
  if (!copyAndPasteEnabled) {
    return;
  }  
  if ([textView hasSelection]) {
    UITouch *theTouch = [touches anyObject];
    CGPoint point = [theTouch locationInView:self];
    [textView setSelectionEnd:point];
  }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesEnded:touches withEvent:event];
  if (!copyAndPasteEnabled) {
    return;
  }
  CGRect rect = [textView cursorRegion];
  if ([textView hasSelection]) {
    UITouch *theTouch = [touches anyObject];
    [textView setSelectionEnd:[theTouch locationInView:self]];
    rect = [textView selectionRegion];
    if (fabs(rect.size.width) < 1 && fabs(rect.size.height) < 1) {
      rect = [textView cursorRegion];
    }
  }
  
  // bring up editing menu.
  UIMenuController *theMenu = [UIMenuController sharedMenuController];
  [theMenu setTargetRect:rect inView:self];
  [theMenu setMenuVisible:YES animated:YES];
}

- (void)setCopyPasteEnabled:(BOOL)enabled;
{
  copyAndPasteEnabled = enabled;
  // Reset any previous UI state for copy and paste
  UIMenuController *theMenu = [UIMenuController sharedMenuController];
  [theMenu setMenuVisible:NO];
  [textView clearSelection];
}

- (void)setFont:(UIFont*)font
{
  [textView setFont:font];
}

- (ColorMap*)colorMap
{
  return [textView colorMap];
}

@end
