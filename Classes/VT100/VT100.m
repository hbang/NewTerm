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

- (id) init
{
  self = [super init];
  if (self != nil) {
    terminal = [[VT100Terminal alloc] init];
    screen = [[VT100Screen alloc] init];
    [screen setTerminal:terminal];
    [terminal setScreen:screen];
    [terminal setEncoding:NSUTF8StringEncoding];

    [screen resizeWidth:kDefaultWidth height:kDefaultHeight];
    [screen setRefreshDelegate:self];
  }
  return self;
}

- (void) dealloc
{
  [terminal release];
  [screen release];
  [super dealloc];
}

// This object itself is the refresh delegate for the screen.  When we're
// invoked, invoke our refresh delegate and then reset the dirty bits on the
// screen since we should have now refreshed the screen.
- (void)refresh
{
  [refreshDelegate refresh];
  [screen resetDirty];
}

- (void)readInputStream:(NSData*)data
{
  // Push the input stream into the terminal, then parse the stream back out as
  // a series of tokens and feed them back to the screen
  [terminal putStreamData:data];
  VT100TCC token;
  while((token = [terminal getNextToken]),
        token.type != VT100_WAIT && token.type != VT100CC_NULL) {
    // process token
    if (token.type != VT100_SKIP) {
      if (token.type == VT100_NOTSUPPORT) {
        NSLog(@"%s(%d):not support token", __FILE__ , __LINE__);
      } else {
        [screen putToken:token];
      }
    } else {
      NSLog(@"%s(%d):skip token", __FILE__ , __LINE__);
    }
  }
  // Cause the text display to determine if it should re-draw anything
  [screen.refreshDelegate refresh];
}

- (void)setScreenSize:(ScreenSize)size
{
  [screen resizeWidth:size.width height:size.height];
}

- (ScreenSize)screenSize
{
  ScreenSize size;
  size.width = [screen width];
  size.height = [screen height];
  return size;
}

- (ScreenPosition)cursorPosition
{
  ScreenPosition position;
  position.x = [screen cursorX];
  position.y = [screen cursorY];
  return position;
}

- (screen_char_t*)bufferForRow:(int)row
{
  return [screen getLineAtIndex:row];
}

- (void)clearScreen
{
  // Clears both the screen and scrollback buffer
  [screen clearBuffer];
}

- (int)numberOfRows
{
  return [screen numberOfLines];
}

- (BOOL)hasSelection
{
  return selectionStart.x != -1 && selectionStart.y != -1 &&
    selectionEnd.x != -1 && selectionEnd.y != -1;
}

- (void)clearSelection
{
  selectionStart.x = -1;
  selectionStart.y = -1;
  selectionEnd.x = -1;
  selectionEnd.y = -1;
}

- (void)setSelectionStart:(ScreenPosition)point
{
  selectionStart = point;
}

- (ScreenPosition)selectionStart
{
  return selectionStart;
}

- (void)setSelectionEnd:(ScreenPosition)point
{
  selectionEnd = point;
}

- (ScreenPosition)selectionEnd
{
  return selectionEnd;
}


@end
