// PTY.m
// MobileTerminal

#import "HBNTPTY.h"

#include <sys/ttycom.h>
#include <sys/ioctl.h>

@implementation HBNTPTY {
	NSFileHandle *_handle;
	int _width;
	int _height;
}

- (instancetype)init {
	return [self initWithFileHandle:nil];
}

- (instancetype)initWithFileHandle:(NSFileHandle *)fileHandle {
	self = [super init];
	
	if (self) {
		_handle = fileHandle;
		
		// Initialize with the current window size
		struct winsize window_size;
		
		if (ioctl(_handle.fileDescriptor, TIOCGWINSZ, &window_size) == -1) {
			[NSException raise:@"IOException" format:@"Unable to read the terminal size: (%d: %s)", errno, strerror(errno)];
		}
		
		_width = window_size.ws_col;
		_height = window_size.ws_row;
	}
	
	return self;
}

- (void)setWidth:(int)terminalWidth withHeight:(int)terminalHeight; {
	if (_width == terminalWidth && _height == terminalHeight) {
		// Nothing changed
		return;
	}
	
	_width = terminalWidth;
	_height = terminalHeight;
	
	// Update the window size of the forked pty
	struct winsize window_size;
	window_size.ws_col = _width;
	window_size.ws_row = _height;
	
	if (ioctl(_handle.fileDescriptor, TIOCSWINSZ, &window_size) == -1) {
		[NSException raise:@"IOException" format:@"Unable to write the terminal size (%d: %s)", errno, strerror(errno)];
	}
}

@end
