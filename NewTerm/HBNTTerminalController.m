//
//  HBNTTerminalController.m
//  NewTerm
//
//  Created by Adam D on 22/01/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

#import "HBNTTerminalController.h"
#import "HBNTTerminalSessionViewController.h"
#import "HBNTSubProcess.h"
#import "HBNTPTY.h"
#import "HBNTPreferences.h"
#import "VT100.h"
#import "VT100StringSupplier.h"
#import "VT100ColorMap.h"
#import "FontMetrics.h"

@interface HBNTTerminalController () <ScreenBufferRefreshDelegate>

@end

@implementation HBNTTerminalController {
	VT100 *_buffer;
	VT100StringSupplier *_stringSupplier;
	dispatch_queue_t _updateQueue;
	dispatch_queue_t _secondaryUpdateQueue;

	HBNTSubProcess *_subProcess;
	HBNTPTY *_pty;

	BOOL _processEnded;
}

- (instancetype)init {
	self = [super init];

	if (self) {
		// create a serial background queue for updating the text view, using the address of self to
		// make the name unique
		_updateQueue = dispatch_queue_create([NSString stringWithFormat:@"ws.hbang.Terminal.foreground-update-queue-%p", self].UTF8String, DISPATCH_QUEUE_SERIAL);
		_secondaryUpdateQueue = dispatch_queue_create([NSString stringWithFormat:@"ws.hbang.Terminal.update-queue-secondary-%p", self].UTF8String, DISPATCH_QUEUE_SERIAL);

		_buffer = [[VT100 alloc] init];
		_buffer.refreshDelegate = self;

		_stringSupplier = [[VT100StringSupplier alloc] init];
		_stringSupplier.screenBuffer = _buffer;

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesUpdated) name:HBPreferencesDidChangeNotification object:nil];
		[self preferencesUpdated];
	}

	return self;
}

#pragma mark - Screen Buffer

// TODO: this is pretty ugly. maybe we should just be a VT100 subclass?

- (id <ScreenBufferRefreshDelegate>)refreshDelegate {
	return _buffer.refreshDelegate;
}

- (void)setRefreshDelegate:(id <ScreenBufferRefreshDelegate>)refreshDelegate {
	_buffer.refreshDelegate = refreshDelegate;
}

- (ScreenSize)screenSize {
	return _buffer.screenSize;
}

- (void)setScreenSize:(ScreenSize)screenSize {
	// Send the terminal the actual size of our vt100 view. This should be called any time we change
	// the size of the view. This should be a no-op if the size has not changed since the last time we
	// called it.
	_buffer.screenSize = screenSize;
	[_pty setWidth:screenSize.width withHeight:screenSize.height];
}

- (void)readInputStream:(NSData *)data {
	// Simply forward the input stream down the VT100 processor. When it notices
	// changes to the screen, it should invoke our refresh delegate below.
	[_buffer readInputStream:data];
}

- (void)clearScreen {
	[_buffer clearScreen];
}

- (int)scrollbackLines {
	return _buffer.scrollbackLines;
}

- (VT100ColorMap *)colorMap {
	return _stringSupplier.colorMap;
}

- (FontMetrics *)fontMetrics {
	return _stringSupplier.fontMetrics;
}

#pragma mark - Screen Buffer Delegate

- (void)refresh {
	// TODO: we should handle the scrollback separately so it only appears if the user scrolls
	dispatch_async(_updateQueue, ^{
		NSMutableAttributedString *attributedString = _stringSupplier.attributedString;
		UIColor *backgroundColor = _stringSupplier.colorMap.background;

		dispatch_async(dispatch_get_main_queue(), ^{
			[_delegate refreshWithAttributedString:attributedString backgroundColor:backgroundColor];
		});

		dispatch_async(_secondaryUpdateQueue, ^{
			[_stringSupplier detectLinksForAttributedString:attributedString];

			dispatch_async(dispatch_get_main_queue(), ^{
				[_delegate refreshWithAttributedString:attributedString backgroundColor:backgroundColor];
			});
		});
	});
}

- (void)activateBell {
	[_delegate activateBell];
}

#pragma mark - Sub Process

- (void)startSubProcess {
	_processEnded = NO;

	_subProcess = [[HBNTSubProcess alloc] init];
	[_subProcess start];

	// The PTY will be sized correctly on the first call to layoutSubViews
	_pty = [[HBNTPTY alloc] initWithFileHandle:_subProcess.fileHandle];

	// Schedule an async read of the subprocess. Invokes our callback when data becomes available.
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataAvailable:) name:NSFileHandleReadCompletionNotification object:_subProcess.fileHandle];
	[_subProcess.fileHandle readInBackgroundAndNotify];
}

- (void)dataAvailable:(NSNotification *)notification {
	NSData *data = notification.userInfo[NSFileHandleNotificationDataItem];

	if (data.length == 0) {
		// zero-length data is an indicator of EOF. this can happen if the user exits the terminal by
		// typing `exit`, or if there’s a catastrophic failure (e.g. /bin/login is broken). we print a
		// message to the terminal saying the process ended, and then when the user presses any key, the
		// tab will close
		NSString *message = [NSString stringWithFormat:@"[%@]\r\n%@\r\n", NSLocalizedString(@"PROCESS_COMPLETED_TITLE", @"Title displayed when the terminal’s process has ended."), NSLocalizedString(@"PROCESS_COMPLETED_MESSAGE", @"Message indicating the user can press any key to close the tab.")];
		[self readInputStream:[message dataUsingEncoding:NSUTF8StringEncoding]];

		_processEnded = YES;
		[_subProcess stop];
	} else {
		// Forward the subprocess data into the terminal character handler
		[self readInputStream:data];

		// Queue another read
		[_subProcess.fileHandle readInBackgroundAndNotify];
	}
}

- (void)stopSubProcess {
	_processEnded = YES;
	[_subProcess stop];
}

- (void)receiveKeyboardInput:(NSData *)data {
	if (_processEnded) {
		// The sub process previously exited, close it at the users request.
		[_viewController close];
	} else {
		// Forward the data from the keyboard directly to the subprocess
		[_subProcess.fileHandle writeData:data];
	}
}

#pragma mark - Preferences

- (void)preferencesUpdated {
	HBNTPreferences *preferences = [HBNTPreferences sharedInstance];
	_stringSupplier.colorMap = preferences.colorMap;
	_stringSupplier.fontMetrics = preferences.fontMetrics;
	
	[self refresh];
}

#pragma mark - NSObject

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
