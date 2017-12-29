// VT100RowStringSupplier.h
// MobileTerminal

#import "VT100Types.h"

@class VT100ColorMap, FontMetrics;

@interface VT100StringSupplier : NSObject <AttributedStringSupplier>

@property (nonatomic, retain) id <ScreenBuffer> screenBuffer;
@property (nonatomic, retain) VT100ColorMap *colorMap;

- (int)rowCount;

- (NSString *)stringForLine:(int)rowIndex;
- (NSMutableAttributedString *)attributedStringWithFontMetrics:(FontMetrics *)fontMetrics;

@end
