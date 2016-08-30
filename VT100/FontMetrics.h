// FontMetrics.h
// MobileTerminal
//
//

@import CoreText;

@interface FontMetrics : NSObject

- (instancetype)initWithFont:(UIFont *)font;

@property (nonatomic, retain, readonly) UIFont *font;

// The dimensions of a single glyph on the screen
@property (nonatomic, readonly) CGSize boundingBox;
@property (nonatomic, readonly) CGFloat descent;
@property (nonatomic, readonly) CGFloat ascent;
@property (nonatomic, readonly) CGFloat leading;

@end
