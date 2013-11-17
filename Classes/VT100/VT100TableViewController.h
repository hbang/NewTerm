// VT100TableViewController.h
// MobileTerminal


#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@class ColorMap;
@class FontMetrics;
@class VT100;
@class TerminalController;
@protocol AttributedStringSupplier;
@protocol ScreenBuffer;
@protocol RefreshDelegate;

@interface VT100TableViewController : UITableViewController

@property (nonatomic, retain) FontMetrics *fontMetrics;
@property (nonatomic, retain) id<AttributedStringSupplier> stringSupplier;
@property (nonatomic, retain) VT100 *buffer;
@property (nonatomic, retain) ColorMap *colorMap;
@property (nonatomic, retain) TerminalController *terminalController;
@property (nonatomic, retain) UIFont *font;

- (void)refresh;

// Returns the height and width of the terminal in characters
- (int)width;
- (int)height;

// Process an input stream of data
- (void)readInputStream:(NSData *)data;

- (void)clearScreen;
- (void)scrollToBottomAnimated:(BOOL)animated;

// Methods for selecting text displayed by the terminal (independent of cursor
// position).	 Selected text is displayed by changing the background color
// to look like the cursor.	 Perhaps this should be improved to display the
// same UI as a text field that is selected for copy and paste, with selector
// bars.	The CGPoints are positions in the view
- (void)clearSelection;
- (void)setSelectionStart:(CGPoint)point;
- (void)setSelectionEnd:(CGPoint)point;
- (BOOL)hasSelection;
// An approximation of the selection region
- (CGRect)selectionRegion;
// Copies the UTF8 text selected on the screen into the specified data object
- (void)fillDataWithSelection:(NSMutableData *)data;

// Rectangle that represents the position where the cursor is drawn
- (CGRect)cursorRegion;

@end
