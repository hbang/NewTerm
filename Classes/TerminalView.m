// TerminalView.m
// MobileTerminal

#import "TerminalView.h"

#import "VT100/VT100TextView.h"
#import "SubProcess/SubProcess.h"

@implementation TerminalView

- (void)dataAvailable:(NSNotification *)aNotification {
  // Forward the subprocess data into the terminal character handler
  NSData* data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
  [textView readInputStream:data];
  
  // Queue another read
  [[subProcess fileHandle] readInBackgroundAndNotify];
}

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super initWithCoder:decoder];
  if (self != nil) {
    subProcess = [[SubProcess alloc] init];
    pty = NULL;    
    textView = [[VT100TextView alloc] initWithCoder:decoder];
    [textView setFrame:self.frame];
    [self addSubview:textView];
    
    // Prepare subprocess stuff
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
  return self;
}

- (void)dealloc {
  [pty release];
  [subProcess stop];
  [subProcess release];
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
  // Forward the data from the keyboard directly to the subprocess
  [[subProcess fileHandle] writeData:data];
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
