// PTY.h
// MobileTerminal

#import <Foundation/Foundation.h>

// Controls settings on PTY, currently just width and height.
@interface PTY : NSObject {
@private;
  NSFileHandle* handle;
  int width;
  int height;
}

- (id)initWithFileHandle:(NSFileHandle*)fileHandle;

// Adjust the height and width of the subprocess terminal.
- (void)setWidth:(int)terminalWidth withHeight:(int)terminalHeight;

@end
