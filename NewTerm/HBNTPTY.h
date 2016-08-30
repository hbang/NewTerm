// PTY.h
// MobileTerminal

// Controls settings on PTY, currently just width and height.
@interface HBNTPTY : NSObject

- (instancetype)initWithFileHandle:(NSFileHandle *)fileHandle;

// Adjust the height and width of the subprocess terminal.
- (void)setWidth:(int)terminalWidth withHeight:(int)terminalHeight;

@end
