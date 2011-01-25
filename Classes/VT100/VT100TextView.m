// VT100TextView.m
// VT100

#import "VT100TextView.h"
#import "ColorMap.h"
#import "FontMetrics.h"
#import "VT100.h"
#import "VT100StringSupplier.h"
#import "VT100TableViewController.h"

// Percentage of this view that does not allow scrolling.  See hitTest.
static const double kSwipeWidth = 0.85;

extern void CGFontGetGlyphsForUnichars(CGFontRef, unichar[], CGGlyph[], size_t);

@interface VT100TextView (RefreshDelegate) <ScreenBufferRefreshDelegate>
- (void)refresh;
@end

@implementation VT100TextView

@synthesize buffer;
@synthesize colorMap;

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super initWithCoder:decoder];
  if (self != nil) {
    VT100* vt100 = [[VT100 alloc] init];
    [vt100 setRefreshDelegate:self];
    buffer = vt100;
    colorMap = [[ColorMap alloc] init];
    UIFont* font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    fontMetrics = [[FontMetrics alloc] initWithFont:font];
    [self clearSelection];
    
    VT100StringSupplier* stringSupplier = [[VT100StringSupplier alloc] init];
    stringSupplier.colorMap = colorMap;
    stringSupplier.screenBuffer = buffer;
    
    tableViewController = [[VT100TableViewController alloc] initWithColorMap:colorMap];
    tableViewController.stringSupplier = stringSupplier;
    tableViewController.fontMetrics = fontMetrics;
    [self addSubview:tableViewController.tableView];
    
    [stringSupplier release];
  }
  return self;
}

- (void)dealloc
{
  [colorMap release];
  [buffer release];
  [super dealloc];
}

- (void)setFont:(UIFont*)font;
{
  [fontMetrics release];
  fontMetrics = [[FontMetrics alloc] initWithFont:font];
  tableViewController.fontMetrics = fontMetrics;
}

- (void)layoutSubviews
{
  [super layoutSubviews];

  CGSize glyphSize = [fontMetrics boundingBox];
  
  // Determine the screen size based on the font size
  CGSize frameSize = [self frame].size;
  ScreenSize size;
  size.width = (int)(frameSize.width / glyphSize.width);
  size.height = (int)(frameSize.height / glyphSize.height);
  // The font size should not be too small that it overflows the glyph buffers.
  // It is not worth the effort to fail gracefully (increasing the buffer size would
  // be better).
  NSParameterAssert(size.width < kMaxRowBufferSize);
  [buffer setScreenSize:size];
  
  tableViewController.tableView.frame = self.frame;
}

- (int)width
{
  return [buffer screenSize].width;
}

- (int)height
{
  return [buffer screenSize].height;
}

- (int)adjacentCharactersWithSameColor:(screen_char_t*)data withSize:(int)length
{
  int i = 1;
  for (i = 1; i < length; ++i) {
    if (data[0].fg_color != data[i].fg_color) {
      break;
    }
  }
  return i;
}

- (ScreenPosition)positionFromPoint:(CGPoint)point
{
  CGSize glyphSize = [fontMetrics boundingBox];

  ScreenPosition pos;
  pos.x = point.x / glyphSize.width;
  pos.y = (point.y - (glyphSize.height / 2)) / glyphSize.height;
  return pos;
}

- (void)readInputStream:(NSData*)data
{
  // Simply forward the input stream down the VT100 processor.  When it notices
  // changes to the screen, it should invoke our refresh delegate below.
  [buffer readInputStream:data];
}

- (void)clearScreen
{
  [buffer clearScreen];
}

- (void)clearSelection
{
  [buffer clearSelection];
  [self refresh];
}

- (void)setSelectionStart:(CGPoint)point
{
  [buffer setSelectionStart:[self positionFromPoint:point]];
}

- (void)setSelectionEnd:(CGPoint)point
{
  [buffer setSelectionEnd:[self positionFromPoint:point]];
  [self refresh];
}

- (void)fillDataWithSelection:(NSMutableData*)data
{
  NSMutableString* s = [[NSMutableString alloc] initWithString:@""];

  ScreenPosition startPos = [buffer selectionStart];
  ScreenPosition endPos = [buffer selectionEnd];
  if (startPos.x >= endPos.x &&
      startPos.y >= endPos.y) {
    ScreenPosition tmp = startPos;
    startPos = endPos;
    endPos = tmp;
  }
  
  int currentY = startPos.y;
  int maxX = [self width];
  while (currentY <= endPos.y) {
    int startX = (currentY == startPos.y) ? startPos.x : 0;
    int endX = (currentY == endPos.y) ? endPos.x : maxX;
    int width = endX - startX;
    if (width > 0) {
      screen_char_t* row = [buffer bufferForRow:currentY];
      screen_char_t* col = &row[startX];
      unichar buf[kMaxRowBufferSize];
      for (int i = 0; i < width; ++i) {
        if (col->ch == '\0') {
          buf[i] = ' ';
        } else {
          buf[i] = col->ch;
        }
        ++col;
      }
      [s appendString:[NSString stringWithCharacters:buf length:width]];
    }
    ++currentY;
  }
  [data appendData:[s dataUsingEncoding:NSUTF8StringEncoding]];
  [s release];
}

- (BOOL)hasSelection
{
  return [buffer hasSelection];
}

- (CGRect)scaleRect:(CGRect)rect
{
  CGSize glyphSize = [fontMetrics boundingBox];
  rect.origin.x *= glyphSize.width;
  rect.origin.y *= glyphSize.height;
  rect.size.width *= glyphSize.width;
  rect.size.height *= glyphSize.height;
  return rect;
}

- (CGRect)cursorRegion
{
  ScreenPosition cursorPosition = [buffer cursorPosition];
  CGRect rect = CGRectMake(cursorPosition.x, cursorPosition.y, 1, 1);
  return [self scaleRect:rect];
}

- (CGRect)selectionRegion
{
  ScreenPosition selectionStart = [buffer selectionStart];
  ScreenPosition selectionEnd = [buffer selectionEnd];
  CGRect rect;
  if (selectionStart.x >= selectionEnd.x &&
      selectionStart.y >= selectionEnd.y) {
    rect = CGRectMake(selectionEnd.x,
                      selectionEnd.y,
                      selectionStart.x - selectionEnd.x,
                      selectionStart.y - selectionEnd.y);
  } else {
    rect = CGRectMake(selectionStart.x,
                      selectionStart.y,
                      selectionEnd.x - selectionStart.x,
                      selectionEnd.y - selectionStart.y);
  }
  return [self scaleRect:rect];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
  // Allow scrolling on the right side of the view near the scrollbar.
  // Otherwise, bubble up hit events to the gesture recognizer.
  if (point.x > [self frame].size.width * kSwipeWidth) {
    return [super hitTest:point withEvent:event];
  }
  return NULL;
}

@end

@implementation VT100TextView (RefreshDelegate)

- (void)refresh
{
  // TODO(allen): Is it possible to only refresh the dirty bits?
  [tableViewController refresh];
}

@end
