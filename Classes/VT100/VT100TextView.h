// VT100TextView.h
// MobileTeterminal
//
// A UI component for rendering a VT100 display in a view.  The VT100TextView
// can be fed VT100 character stream data in chunks which is then rendered.

#import <UIKit/UIKit.h>

@class ColorMap;
@class VT100;
@protocol ScreenBuffer;
@protocol RefreshDelegate;

@interface VT100TextView : UIView {
@private
  id <ScreenBuffer> buffer;
  UIFont* font;
  CGSize fontSize;  
  CGFontRef cgFont;

  // Total height of the cursor, including what dips below the baseline
  CGFloat cursorHeight;
  CGFloat cursorHeightFromBaseline;
  
  ColorMap* colorMap;
  
  // Buffer of characters to draw on the screen, holds up to one row
  CGGlyph* glyphBuffer;
  CGSize* glyphAdvances;

  // Points on the screen
  CGPoint selectionStart;
  CGPoint selectionEnd;
}

@property (nonatomic, retain) IBOutlet id <ScreenBuffer> buffer;
@property (nonatomic, retain) IBOutlet ColorMap* colorMap;

// Sets the font to display on the screen.  This will likely change the width
// and height of the terminal.
- (void)setFont:(UIFont*)font;
- (UIFont*)font;

// Returns the height and width of the terminal in characters
- (int)width;
- (int)height;

// Process an input stream of data
- (void)readInputStream:(NSData*)data;

- (void)clearScreen;

// Methods for selecting text displayed by the terminal (independent of cursor
// position).  Selected text is displayed by changing the background color
// to look like the cursor.  Perhaps this should be improved to display the
// same UI as a text field that is selected for copy and paste, with selector
// bars.  The CGPoints are positions in the view
- (void)clearSelection;
- (void)setSelectionStart:(CGPoint)point;
- (void)setSelectionEnd:(CGPoint)point;
- (BOOL)hasSelection;
// An approximation of the selection region
- (CGRect)selectionRegion;
// Copies the UTF8 text selected on the screen into the specified data object
- (void)fillDataWithSelection:(NSMutableData*)data;

// Rectangle that represents the position where the cursor is drawn
- (CGRect)cursorRegion;

@end
