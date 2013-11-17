// TerminalController.m
// MobileTerminal

#import "TerminalController.h"

#import "VT100/ColorMap.h"
#import "VT100/VT100TableViewController.h"
#import "SubProcess/SubProcess.h"

@interface TerminalController () {
	SubProcess *_subProcess;
	PTY *_pty;
	
	// Keeps track of when the subprocess is stopped, so that we know to start
	// a new one on key press.
	BOOL _stopped;
	
	// Determines if this view responds to touch events as copy and paste
	BOOL _copyAndPasteEnabled;
}

@end

@implementation TerminalController

- (instancetype)init {
	self = [super init];
	if (self != nil) {
		_subProcess = nil;
		_copyAndPasteEnabled = NO;
		_tableViewController = [[VT100TableViewController alloc] init];
		_tableViewController.terminalController = self;
	}
	return self;
}

- (void)dealloc {
	[self releaseSubProcess];
	[super dealloc];
}

- (void)layoutSubviews {
	// Make sure that the text view is laid out, which re-computes the terminal
	// size in rows and columns.
	[_tableViewController viewWillLayoutSubviews];

	// Send the terminal the actual size of our vt100 view.	 This should be
	// called any time we change the size of the view.	This should be a no-op if
	// the size has not changed since the last time we called it.
	[_pty setWidth:[_tableViewController width] withHeight:[_tableViewController height]];
}

#pragma mark - Subprocesses

// Initializes the sub process and pty object.	This sets up a listener that
// invokes a callback when data from the subprocess is available.
- (void)startSubProcess {
	_stopped = NO;
	
	_subProcess = [[SubProcess alloc] init];
	[_subProcess start];
	
	// The PTY will be sized correctly on the first call to layoutSubViews
	_pty = [[PTY alloc] initWithFileHandle:_subProcess.fileHandle];
	
	// Schedule an async read of the subprocess.	Invokes our callback when
	// data becomes available.
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataAvailable:) name:NSFileHandleReadCompletionNotification object:_subProcess.fileHandle];
	[[_subProcess fileHandle] readInBackgroundAndNotify];
}

- (void)releaseSubProcess {
	if (_subProcess == nil) {
		return;
	}
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	_stopped = YES;
	[_pty release];
	[_subProcess stop];
	[_subProcess release];
}

static const char *kProcessExitedMessage =
"[Process completed]\r\n"
"Press any key to restart.\r\n";

- (void)dataAvailable:(NSNotification *)aNotification {
	NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	if ([data length] == 0) {
		// I would expect from the documentation that an EOF would be present as
		// an entry in the userinfo dictionary as @"NSFileHandleError", but that is
		// never present.	 Instead, it seems to just appear as an empty data
		// message.	 This usually happens when someone just types "exit".	 Simply
		// restart the subprocess when this happens.
		
		// On EOF, either (a) the user typed "exit" or (b) the terminal never
		// started in first place due to a misconfiguration of the BSD subsystem
		// (can't find /bin/login, etc).	To allow the user to proceed in case (a),
		// display a message with instructions on how to restart the shell.	 We
		// don't restart automatically in case of (b), which would put us in an
		// infinite loop.	 Print a message on the screen with instructions on how
		// to restart the process.
		NSData *message = [NSData dataWithBytes:kProcessExitedMessage length:strlen(kProcessExitedMessage)];
		[_tableViewController readInputStream:message];
		[self releaseSubProcess];
		return;
	}
	
	// Forward the subprocess data into the terminal character handler
	[_tableViewController readInputStream:data];
	
	// Queue another read
	[[_subProcess fileHandle] readInBackgroundAndNotify];
}

#pragma mark - Keyboard

- (void)receiveKeyboardInput:(NSData *)data {
	if (_stopped) {
		// The sub process previously exited, restart it at the users request.
		[_tableViewController clearScreen];
		[self startSubProcess];
	} else {
		// Forward the data from the keyboard directly to the subprocess
		[[_subProcess fileHandle] writeData:data];
	}
}

- (void)fillDataWithSelection:(NSMutableData *)data; {
	return [_tableViewController fillDataWithSelection:data];
}

#pragma mark - Gestures

// TODO: reimplement with gesture recognizer
/*
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesBegan:touches withEvent:event];
	if (!copyAndPasteEnabled) {
		return;
	}	 
	if ([tableViewController hasSelection]) {
		[tableViewController clearSelection];
	} else {
		UITouch *theTouch = [touches anyObject];
		CGPoint point = [theTouch locationInView:self];
		[tableViewController setSelectionStart:point];
		[tableViewController setSelectionEnd:point];
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesMoved:touches withEvent:event];
	if (!copyAndPasteEnabled) {
		return;
	}	 
	if ([tableViewController hasSelection]) {
		UITouch *theTouch = [touches anyObject];
		CGPoint point = [theTouch locationInView:self];
		[tableViewController setSelectionEnd:point];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesEnded:touches withEvent:event];
	if (!copyAndPasteEnabled) {
		return;
	}
	CGRect rect = [tableViewController cursorRegion];
	if ([tableViewController hasSelection]) {
		UITouch *theTouch = [touches anyObject];
		[tableViewController setSelectionEnd:[theTouch locationInView:self]];
		rect = [tableViewController selectionRegion];
		if (fabs(rect.size.width) < 1 && fabs(rect.size.height) < 1) {
			rect = [tableViewController cursorRegion];
		}
	}
	
	// bring up editing menu.
	UIMenuController *theMenu = [UIMenuController sharedMenuController];
	[theMenu setTargetRect:rect inView:self];
	[theMenu setMenuVisible:YES animated:YES];
}
*/

#pragma mark - Setters

- (BOOL)copyAndPasteEnabled {
	return _copyAndPasteEnabled;
}

- (void)setCopyPasteEnabled:(BOOL)enabled; {
	_copyAndPasteEnabled = enabled;
	// Reset any previous UI state for copy and paste
	[UIMenuController sharedMenuController].menuVisible = NO;
	[_tableViewController clearSelection];
}

- (UIFont *)font {
	return _tableViewController.font;
}

- (void)setFont:(UIFont *)font {
	_tableViewController.font = font;
}

- (ColorMap *)colorMap {
	return _tableViewController.colorMap;
}

- (void)setColorMap:(ColorMap *)colorMap {
	_tableViewController.colorMap = colorMap;
}

@end
