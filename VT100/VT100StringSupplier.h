// VT100RowStringSupplier.h
// MobileTerminal

#import "VT100Types.h"

@class VT100ColorMap, FontMetrics;

@interface VT100StringSupplier : NSObject <AttributedStringSupplier>

@property (nonatomic, weak) id <ScreenBuffer> screenBuffer;
@property (nonatomic, strong) VT100ColorMap *colorMap;
@property (nonatomic, strong) FontMetrics *fontMetrics;

- (int)rowCount;

- (NSString *)stringForLine:(int)rowIndex;
- (NSMutableAttributedString *)attributedString;

@end
