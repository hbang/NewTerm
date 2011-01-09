// VT100TextView.h
// MobileTeterminal
//
// A UI component for rendering a VT100 display in a view.  The VT100TextView
// can be fed VT100 character stream data in chunks which is then rendered.

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@class FontMetrics;
@class ColorMap;
@class VT100;
@class VT100TableViewController;
@protocol ScreenBuffer;
@protocol RefreshDelegate;

@interface VT100TextView : UIView {
@private
  // The lines of text are displayed via a table view
  VT100TableViewController* tableViewController;
  
  id <ScreenBuffer> buffer;
  FontMetrics* fontMetrics;
  
  ColorMap* colorMap;
}

@property (nonatomic, retain) IBOutlet id <ScreenBuffer> buffer;
@property (nonatomic, retain) IBOutlet ColorMap* colorMap;

// Sets the font to display on the screen.
// The caller should likely also call setNeedsLayout on this object.
- (void)setFont:(UIFont*)font;

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
