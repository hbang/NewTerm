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

@implementation HBNTTerminalController {
	HBNTSubProcess *_subProcess;
	HBNTPTY *_pty;

	BOOL _processEnded;
}

- (void)updateScreenSize {
	// Send the terminal the actual size of our vt100 view. This should be called any time we change
	// the size of the view. This should be a no-op if the size has not changed since the last time we
	// called it.
	[_pty setWidth:_viewController.screenWidth withHeight:_viewController.screenHeight];
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
		[_viewController readInputStream:[message dataUsingEncoding:NSUTF8StringEncoding]];

		_processEnded = YES;
		[_subProcess stop];
	} else {
		// Forward the subprocess data into the terminal character handler
		[_viewController readInputStream:data];

		// Queue another read
		[_subProcess.fileHandle readInBackgroundAndNotify];
	}
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

#pragma mark - Properties

- (UIFont *)font {
	return _viewController.font;
}

- (void)setFont:(UIFont *)font {
	_viewController.font = font;
}

- (VT100ColorMap *)colorMap {
	return _viewController.colorMap;
}

- (void)setColorMap:(VT100ColorMap *)colorMap {
	_viewController.colorMap = colorMap;
}

#pragma mark - NSObject

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
