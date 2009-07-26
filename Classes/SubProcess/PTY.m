// PTY.m
// MobileTerminal

#import "PTY.h"

#include <sys/ttycom.h>
#include <sys/ioctl.h>

@implementation PTY

- (id) init
{
  return [self initWithFileHandle:nil];
}

- (id) initWithFileHandle:(NSFileHandle*)fileHandle
{
  self = [super init];
  if (self != nil) {
    self->handle = fileHandle;
    // Initialize with the current window size
    struct winsize window_size;
    if (ioctl([handle fileDescriptor], TIOCGWINSZ, &window_size) == -1) {
      [NSException raise:@"IOException"
                  format:@"Unable to read the terminal size: (%d: %s)", errno,
                         strerror(errno)];
    }
    width = window_size.ws_col;
    height = window_size.ws_row;
  }
  return self;
}

- (void)setWidth:(int)terminalWidth withHeight:(int)terminalHeight;
{
  if (width == terminalWidth && height == terminalHeight) {
    // Nothing changed
    return;
  }
  width = terminalWidth;
  height = terminalHeight;
  
  // Update the window size of the forked pty
  struct winsize window_size;
  window_size.ws_col = width;
  window_size.ws_row = height;
  if (ioctl([handle fileDescriptor], TIOCSWINSZ, &window_size) == -1) {
    [NSException raise:@"IOException"
                format:@"Unable to write the terminal size (%d: %s)", errno,
                       strerror(errno)];
  }
}

@end
