// VT100.m
// MobileTerminal

#import "VT100.h"

#import "VT100Terminal.h"
#import "VT100Screen.h"

// The default width and height are basically thrown away as soon as the text
// view is initialized and determins the right height and width for the
// current font.
static const int kDefaultWidth = 80;
static const int kDefaultHeight = 25;

@implementation VT100

@synthesize refreshDelegate;

- (id) init {
	self = [super init];

	if (self) {
		_terminal = [[VT100Terminal alloc] init];
		_terminal.encoding = NSUTF8StringEncoding;

		_terminal.primaryScreen.refreshDelegate = self;
		_terminal.alternateScreen.refreshDelegate = self;
		[_terminal.primaryScreen resizeWidth:kDefaultWidth height:kDefaultHeight];
		[_terminal.alternateScreen resizeWidth:kDefaultWidth height:kDefaultHeight];
	}

	return self;
}

// This object itself is the refresh delegate for the screen.	 When we're
// invoked, invoke our refresh delegate and then reset the dirty bits on the
// screen since we should have now refreshed the screen.
- (void)refresh {
	[_refreshDelegate refresh];
	[_terminal.currentScreen resetDirty];
}

- (void)activateBell {
	// tell the refresh delegate to activate the bell
	[_refreshDelegate activateBell];
}

- (void)readInputStream:(NSData *)data {
	// Push the input stream into the terminal, then parse the stream back out as
	// a series of tokens and feed them back to the screen
	[_terminal putStreamData:data];
	VT100Token *token;
	while((token = [_terminal getNextToken]),
				token.type != VT100_WAIT && token.type != VT100CC_NULL) {
		// process token
		if (token.type != VT100_SKIP) {
			if (token.type == VT100_NOTSUPPORT) {
				HBLogDebug(@"not support token");
			} else {
				[_terminal.currentScreen putToken:token];
			}
		} else {
			HBLogDebug(@"skip token");
		}
	}
	// Cause the text display to determine if it should re-draw anything
	[_refreshDelegate refresh];
}

- (ScreenSize)screenSize {
	ScreenSize size;
	size.width = _terminal.currentScreen.width;
	size.height = _terminal.currentScreen.height;
	return size;
}

- (void)setScreenSize:(ScreenSize)size {
	[_terminal.primaryScreen resizeWidth:size.width height:size.height];
	[_terminal.alternateScreen resizeWidth:size.width height:size.height];
}

- (ScreenPosition)cursorPosition {
	ScreenPosition position;
	position.x = _terminal.currentScreen.cursorX;
	position.y = _terminal.currentScreen.cursorY;
	return position;
}

- (screen_char_t*)bufferForRow:(int)row {
	return [_terminal.currentScreen getLineAtIndex:row];
}

- (void)clearScreen {
	// Clears both the screen and scrollback buffer
	[_terminal.currentScreen clearBuffer];
}

- (int)numberOfRows {
	return [_terminal.currentScreen numberOfLines];
}

- (unsigned)scrollbackLines {
	return [_terminal.currentScreen numberOfScrollbackLines];
}

@end
