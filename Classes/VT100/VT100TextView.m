// VT100TextView.m
// VT100

#import "VT100TextView.h"
#import "ColorMap.h"
#import "FontMetrics.h"
#import "VT100.h"

// Buffer space used to draw any particular row.  We assume that drawRect is
// only ever called from the main thread, so we can share a buffer between
// calls.
static const int kMaxRowBufferSize = 200;

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
    // Allocate enough space for any row
    unicharBuffer = (unichar*)malloc(sizeof(unichar) * kMaxRowBufferSize);
    UIFont* font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    fontMetrics = [[FontMetrics alloc] initWithFont:font];
    [self clearSelection];
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
  [self setNeedsLayout];
}

- (void)layoutSubviews
{
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


  [super layoutSubviews];
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

- (void)fillRect:(CGRect)rect
     withContext:(CGContextRef)context
       withColor:(CGColorRef)color
{
  CGContextSetFillColorWithColor(context, color);
  CGContextFillRect(context, rect);
}

- (void)drawCursorBackground:(CGContextRef)context
{
  CGRect cursorRect = [self cursorRegion];
  UIColor* cursorColor = [colorMap backgroundCursor];
  [self fillRect:cursorRect
     withContext:context
       withColor:[cursorColor CGColor]];
}

- (void)drawSelectionBackground:(CGContextRef)context
{
  if (![self hasSelection]) {
    return;
  }
  ScreenPosition startPos = [self positionFromPoint:selectionStart];
  ScreenPosition endPos = [self positionFromPoint:selectionEnd];
  if (startPos.x >= endPos.x &&
      startPos.y >= endPos.y) {
    ScreenPosition tmp = startPos;
    startPos = endPos;
    endPos = tmp;
  }
  
  UIColor* selectionColor = [colorMap backgroundCursor];
  int currentY = startPos.y;
  int maxX = [self width];
  while (currentY <= endPos.y) {
    int startX = (currentY == startPos.y) ? startPos.x : 0;
    int endX = (currentY == endPos.y) ? endPos.x : maxX;
    int width = endX - startX;
    if (width > 0) {
      CGSize glyphSize = [fontMetrics boundingBox];
      CGRect selectionRect;
      selectionRect.origin.x = startX * glyphSize.width;
      selectionRect.origin.y =  currentY * glyphSize.height;
      selectionRect.size.width = width * glyphSize.width;
      selectionRect.size.height = glyphSize.height;
      [self fillRect:selectionRect
         withContext:context
           withColor:[selectionColor CGColor]];
    }
    currentY++;
  }
}

- (CFMutableAttributedStringRef)getAttributedStringForRow:(int)rowIndex
{
  ScreenSize screenSize = [buffer screenSize];
  int width = screenSize.width;
  // TODO(aporter): Make the screen object return an attributed string?
  screen_char_t* row = [buffer bufferForRow:rowIndex];
  for (int j = 0; j < width; ++j) {
    if (row[j].ch == '\0') {
      unicharBuffer[j] = ' ';
    } else {
      unicharBuffer[j] = row[j].ch;
    }
  }
  CFStringRef string = CFStringCreateWithCharacters(NULL, unicharBuffer, width);      
  CFMutableAttributedStringRef attrString =
    CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
  CFAttributedStringReplaceString(attrString, CFRangeMake(0, 0), string);
  CFRelease(string);

  // Update the string with foreground color attributes.  This loop compares the
  // the foreground colors of characters and sets the attribute when it runs
  // into a character of a different color.  It runs one extra time to set the
  // attribute for the run of characters at the end of the line.
  int lastColorIndex = -1;
  int lastColor = -1;
  for (int j = 0; j <= width; ++j) {
    bool eol = (j == width);  // reached end of line
    if (eol || row[j].fg_color != lastColor) {
      if (lastColorIndex != -1) {
        int length = j - lastColorIndex;
        CGColorRef color = [[colorMap color:lastColor] CGColor];
        CFAttributedStringSetAttribute(attrString,
                                       CFRangeMake(lastColorIndex, length),
                                       kCTForegroundColorAttributeName, color);
      }
      if (!eol) {
        lastColorIndex = j;
        lastColor = row[j].fg_color;
      }
    }
  }
  return attrString;
}
  
  
// TODO(allen): This is by no means complete! The old PTYTextView does a lot
// more stuff that needs to be ported -- and it also does it quite efficiently.
- (void)drawRect:(CGRect)rect
{
  // TODO(allen): We currently draw the entire control instead of just the
  // rect that we were asked to update  
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  // TODO(allen): Draw background color based on the character position.  For
  // now just fill the entire screen with the same background.
  UIColor* defaultBackgroundColor = [colorMap background];
  [self fillRect:rect
     withContext:context
       withColor:[defaultBackgroundColor CGColor]];
  
  // TODO(allen): It might be nicer to embed this logic into the VT100Terminal
  // foreground/background so that it is handled by the other logic

  [self drawCursorBackground:context];
  [self drawSelectionBackground:context];
  
  // By default, text is drawn upside down.  Apply a transformation to turn
  // orient the text correctly.
  CGAffineTransform xform = CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, 0.0);
  CGContextSetTextMatrix(context, xform);
  // Walk through the screen and output all characters to the display
  ScreenSize screenSize = [buffer screenSize];
  float glyphHeight = [fontMetrics boundingBox].height;
  float glyphDescent = [fontMetrics descent];
  CTFontRef ctFont = [fontMetrics ctFont];
  for (int i = 0; i < screenSize.height; ++i) {    
    CFMutableAttributedStringRef string = [self getAttributedStringForRow:i];    
    CFAttributedStringSetAttribute(string, CFRangeMake(0, screenSize.width),
                                   kCTFontAttributeName, ctFont);
    
    CTLineRef line = CTLineCreateWithAttributedString(string);
    // The coordinates specified here are the baseline of the line which starts
    // from the top of the next row, plus some offset for the glyph descent
    CGContextSetTextPosition(context, 0.0, (i + 1) * glyphHeight - glyphDescent);
    CTLineDraw(line, context);
    CFRelease(line);
    CFRelease(string);
  }
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
  selectionStart.x = -1;
  selectionStart.y = -1;
  selectionEnd.x = -1;
  selectionEnd.y = -1;
  [self setNeedsDisplay];
}

- (void)setSelectionStart:(CGPoint)point
{
  selectionStart = point;
}

- (void)setSelectionEnd:(CGPoint)point
{
  selectionEnd = point;
  [self setNeedsDisplay];
}

- (void)fillDataWithSelection:(NSMutableData*)data
{
  NSMutableString* s = [[NSMutableString alloc] initWithString:@""];

  ScreenPosition startPos = [self positionFromPoint:selectionStart];
  ScreenPosition endPos = [self positionFromPoint:selectionEnd];
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
}

- (BOOL)hasSelection
{
  return selectionStart.x != -1 && selectionStart.y != -1 &&
         selectionEnd.x != -1 && selectionEnd.y != -1;
}

- (CGRect)selectionRegion
{
  if (selectionStart.x >= selectionEnd.x &&
      selectionStart.y >= selectionEnd.y) {
    return CGRectMake(selectionEnd.x,
                      selectionEnd.y,
                      selectionStart.x - selectionEnd.x,
                      selectionStart.y - selectionEnd.y);
  }
  return CGRectMake(selectionStart.x,
                    selectionStart.y,
                    selectionEnd.x - selectionStart.x,
                    selectionEnd.y - selectionStart.y);
}

- (CGRect)cursorRegion
{
  CGSize glyphSize = [fontMetrics boundingBox];
  ScreenPosition cursorPosition = [buffer cursorPosition];
  CGRect cursorRect;
  cursorRect.origin.x = cursorPosition.x * glyphSize.width;
  cursorRect.origin.y = cursorPosition.y * glyphSize.height;
  cursorRect.size.width = glyphSize.width;
  cursorRect.size.height = glyphSize.height;  
  return cursorRect;
}

@end

@implementation VT100TextView (RefreshDelegate)

- (void)refresh
{
  // TODO(allen): Call setNeedsDisplayInRect for only the dirty bits
  [self setNeedsDisplay];
}

@end
