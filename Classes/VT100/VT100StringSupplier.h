// VT100RowStringSupplier.h
// MobileTerminal

#import <Foundation/Foundation.h>
#import "VT100Types.h"

extern CFStringRef const kBackgroundColorAttributeName;

@class ColorMap;

@interface VT100StringSupplier : NSObject<AttributedStringSupplier> {
@private
  id<ScreenBuffer> screenBuffer;
  ColorMap* colorMap;
}

@property (nonatomic, retain) id <ScreenBuffer> screenBuffer;
@property (nonatomic, retain) ColorMap* colorMap;

- (int)rowCount;
- (CFStringRef)newString:(int)rowIndex;
- (CFAttributedStringRef)newAttributedString:(int)rowIndex;

@end
