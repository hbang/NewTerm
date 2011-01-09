// VT100RowView.m
// MobileTerminal

#import "VT100RowView.h"

#import "FontMetrics.h"
#import "VT100StringSupplier.h"
#import "VT100Types.h"

@implementation VT100RowView

@synthesize rowIndex;
@synthesize stringSupplier;
@synthesize fontMetrics;

- (CFAttributedStringRef)newAttributedString
{
  CTFontRef ctFont = [fontMetrics ctFont];    
  CFAttributedStringRef string = [stringSupplier newAttributedString:rowIndex];
  // Make a new copy of the line of text with the correct font
  int length = CFAttributedStringGetLength(string);
  CFMutableAttributedStringRef stringWithFont =
      CFAttributedStringCreateMutableCopy(kCFAllocatorDefault, length, string);
  CFAttributedStringSetAttribute(stringWithFont, CFRangeMake(0, length),
                                 kCTFontAttributeName, ctFont);
  CFRelease(string);
  return stringWithFont;
}

- (float)textOffset
{
  // The base line of the text from the top of the row plus some offset for the
  // glyph descent.  This assumes that the frame size for this cell is based on
  // the same font metrics
  float glyphHeight = [fontMetrics boundingBox].height;
  float glyphDescent = [fontMetrics descent];  
  return glyphHeight - glyphDescent;
}

// Convert a range of characters in a string to the rect where they are drawn
- (CGRect)rectFromRange:(CFRange)range
{
  CGSize characterBox = [fontMetrics boundingBox];
  return CGRectMake(characterBox.width * range.location, 0.0f,
                    characterBox.width * range.length, characterBox.height);
}


- (void)drawBackground:(CGContextRef)context
             forString:(CFAttributedStringRef)attributedString
{
  // Paints the background in as few steps as possible by finding common runs
  // of text with the same attributes.
  CFRange remaining =
      CFRangeMake(0, CFAttributedStringGetLength(attributedString));  
  while (remaining.length > 0) {
    CFRange effectiveRange;
    CGColorRef backgroundColor =
        (CGColorRef) CFAttributedStringGetAttribute(
            attributedString, remaining.location, kBackgroundColorAttributeName,
            &effectiveRange);
    CGContextSetFillColorWithColor(context, backgroundColor);
    CGContextFillRect(context, [self rectFromRange:effectiveRange]);
    
    remaining.length -= effectiveRange.length;
    remaining.location += effectiveRange.length;
  }
}

- (void)drawRect:(CGRect)rect
{
  NSAssert(fontMetrics != nil, @"fontMetrics not initialized");
  NSAssert(stringSupplier != nil, @"stringSupplier not initialized");
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  CFAttributedStringRef attributedString = [self newAttributedString];
  [self drawBackground:context forString:attributedString];

  // By default, text is drawn upside down.  Apply a transformation to turn
  // orient the text correctly.
  CGAffineTransform xform = CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, 0.0);
  CGContextSetTextMatrix(context, xform);
  CGContextSetTextPosition(context, 0.0, [self textOffset]);
  CTLineRef line = CTLineCreateWithAttributedString(attributedString);
  CTLineDraw(line, context);
  CFRelease(line);
  CFRelease(attributedString);
}

@end
