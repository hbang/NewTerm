// VT100RowStringSupplier.m
// MobileTerminal

#import "VT100StringSupplier.h"

#import <CoreText/CoreText.h>
#import "ColorMap.h"
#import "VT100Types.h"

CFStringRef const kBackgroundColorAttributeName = CFSTR("-background-color-");

@implementation VT100StringSupplier

@synthesize screenBuffer;
@synthesize colorMap;

- (int)rowCount
{
  return [screenBuffer numberOfRows];
}

- (int)columnCount
{
  return [screenBuffer screenSize].width;
}

- (CFStringRef)newString:(int)rowIndex
{
  // Buffer of characters to draw on the screen, holds up to one row
  unichar unicharBuffer[kMaxRowBufferSize];
  
  // TODO(aporter): Make the screen object itself return an attributed string?
  int width = [self columnCount];
  screen_char_t* row = [screenBuffer bufferForRow:rowIndex];
  for (int j = 0; j < width; ++j) {
    if (row[j].ch == '\0') {
      unicharBuffer[j] = ' ';
    } else {
      unicharBuffer[j] = row[j].ch;
    }
  }
  return CFStringCreateWithCharacters(NULL, unicharBuffer, width);      
}

- (CFAttributedStringRef)newAttributedString:(int)rowIndex
{
  CFStringRef string = [self newString:rowIndex];
  CFMutableAttributedStringRef attrString =
      CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
  CFAttributedStringReplaceString(attrString, CFRangeMake(0, 0), string);
  CFRelease(string);
  
  // The cursor is initially relative to the screen, not the position in the
  // scrollback buffer.
  ScreenPosition cursorPosition = [screenBuffer cursorPosition];
  if ([screenBuffer numberOfRows] > [screenBuffer screenSize].height) {
    cursorPosition.y += [screenBuffer numberOfRows] - [screenBuffer screenSize].height;
  }
  
  // Update the string with background/foreground color attributes.  This loop
  // compares the the colors of characters and sets the attribute when it runs
  // into a character of a different color.  It runs one extra time to set the
  // attribute for the run of characters at the end of the line.
  int lastColorIndex = -1;
  UIColor* lastColor = nil;
  screen_char_t* row = [screenBuffer bufferForRow:rowIndex];
  int width = [self columnCount];
  
  // TODO(aporter): This looks a lot more complicated than it needs to be.  Try
  // this again with fewer lines of code.
  for (int j = 0; j <= width; ++j) {
    bool eol = (j == width);  // reached end of line
    UIColor* color = nil;
    if (!eol) {
      color = [colorMap color:row[j].bg_color];
      if (cursorPosition.x == j && cursorPosition.y == rowIndex) {
        color = [colorMap backgroundCursor];
      }
    }
    if (eol || ![color isEqual:lastColor]) {
      if (lastColorIndex != -1) {
        int length = j - lastColorIndex;
        CFAttributedStringSetAttribute(attrString,
                                       CFRangeMake(lastColorIndex, length),
                                       kBackgroundColorAttributeName,
                                       [lastColor CGColor]);
      }
      if (!eol) {
        lastColorIndex = j;
        lastColor = color;
      }
    }
  }
  // Same thing again for foreground color
  lastColorIndex = -1;
  lastColor = nil;
  for (int j = 0; j <= width; ++j) {
    bool eol = (j == width);  // reached end of line
    UIColor* color = nil;
    if (!eol) {
      color = [colorMap color:row[j].fg_color];
      if (cursorPosition.x == j && cursorPosition.y == rowIndex) {
        color = [colorMap foregroundCursor];
      }
    }    
    if (eol || ![color isEqual:lastColor]) {
      if (lastColorIndex != -1) {
        int length = j - lastColorIndex;
        CFAttributedStringSetAttribute(attrString,
                                       CFRangeMake(lastColorIndex, length),
                                       kCTForegroundColorAttributeName,
                                       [lastColor CGColor]);
      }
      if (!eol) {
        lastColorIndex = j;
        lastColor = color;
      }
    }
  }
  return attrString;
}

@end
