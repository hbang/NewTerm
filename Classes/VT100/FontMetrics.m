// FontMetrics.m
// MobileTerminal

#import "FontMetrics.h"

@implementation FontMetrics

- (id)initWithFont:(UIFont*)uiFont;
{
  self = [super init];
  if (self != nil) {
    font = [uiFont retain];
    ctFont = CTFontCreateWithName((CFStringRef)font.fontName, font.pointSize, NULL);
    NSAssert(ctFont != NULL, @"Error in CTFontCreateWithName");  
    
    // This creates a CoreText line that isn't drawn, but used to get the
    // size of a single character.  This will probably fail miserably if used
    // with a non-monospaced font.
    CFStringRef string = CFSTR("A");
    CFMutableAttributedStringRef attrString = 
        CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
    CFAttributedStringReplaceString(attrString, CFRangeMake(0, 0), string);  
    CFAttributedStringSetAttribute(attrString, CFRangeMake(0, CFStringGetLength(string)),
                                   kCTFontAttributeName, ctFont);    
    CTLineRef line = CTLineCreateWithAttributedString(attrString);
    float width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
    CFRelease(line);
    CFRelease(attrString);
    boundingBox = CGSizeMake(width, ascent + descent + leading);
  }
  return self;
}

- (void) dealloc
{
  [font release];
  CFRelease(ctFont);
  [super dealloc];
}

- (UIFont*)font
{
  return font;
}

- (CTFontRef)ctFont
{
  return ctFont;
}

- (CGSize)boundingBox
{
  return boundingBox;
}

- (float)descent
{
  return descent;
}

@end
