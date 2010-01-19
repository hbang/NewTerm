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
  
  BOOL hasSelection;
  CGPoint selectionStart;
  CGPoint selectionEnd;
}

@property (nonatomic, retain) IBOutlet id <ScreenBuffer> buffer;
@property (nonatomic, retain) IBOutlet ColorMap* colorMap;

// Sets the font to display on the screen.  This will likely change the width
// and height of the terminal.
- (void)setFont:(UIFont*)font;
- (UIFont*)font;

// Returns the height and width of the terminal
- (int)width;
- (int)height;

// Process an input stream of data
- (void)readInputStream:(NSData*)data;

- (void)clearScreen;

// Methods for selecting text displayed by the terminal.  This is completely
// independent of the cursor position.  Text is displayed as selected by
// changing the background color to be the same as the cursor color.  Perhaps
// this should be improved to display the same UI as a text field that is
// selected for copy and paste.
- (void)clearSelection;
- (void)setSelectionStart:(CGPoint)point;
- (void)setSelectionEnd:(CGPoint)point;
- (NSData*)getSelectionContents;

@end
