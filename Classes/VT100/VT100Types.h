// VT100Types.h
// MobileTerminal
//
// This header file contains types that are used by both the low level VT100
// components and the higher level text view components so they both do not
// have to depend on each other.

#import <Foundation/Foundation.h>

// Buffer space used to draw any particular row.
static const int kMaxRowBufferSize = 200;

// TODO(allen): Include the dirty bit in this struct
typedef struct screen_char_t {
    unichar ch;  // the actual character
    unsigned int bg_color;  // background color
    unsigned int fg_color;  // foreground color
} screen_char_t;

typedef struct {
  int width;
  int height;
} ScreenSize;

typedef struct {
  int x;
  int y;
} ScreenPosition;

// The protocol for reading and writing data to the terminal screen
@protocol ScreenBuffer <NSObject>
@required

// Return the current size of the screen
- (ScreenSize)screenSize;

// Resize the screen to the specified size.  This is a no-op of the new size
// is the same as the existing size.
- (void)setScreenSize:(ScreenSize)size;

// Return the position of the cursor on the screen
- (ScreenPosition)cursorPosition;

// Row indexes include scrollback
- (screen_char_t*)bufferForRow:(int)row;
- (int)numberOfRows;

- (void)readInputStream:(NSData*)data;

- (void)clearScreen;

- (void)clearSelection;
- (BOOL)hasSelection;
- (void)setSelectionStart:(ScreenPosition)point;
- (ScreenPosition)selectionStart;
- (void)setSelectionEnd:(ScreenPosition)point;
- (ScreenPosition)selectionEnd;

@end

// A thin protocol for implementing a delegate interface with a single method
// that is invoked when the screen needs to be refreshed because at least some
// portion has become invalidated.
@protocol ScreenBufferRefreshDelegate <NSObject>
@required
- (void)refresh;
@end

// Supplies an attributed string for a row of text.  In practice this is just
// a string of screen_char_t converted to an attributed string (text color,
// etc).  The row index includes space in the scrollback buffer.
@protocol AttributedStringSupplier
- (int)rowCount;
- (CFStringRef)newString:(int)rowIndex;
- (CFAttributedStringRef)newAttributedString:(int)rowIndex;
@end


