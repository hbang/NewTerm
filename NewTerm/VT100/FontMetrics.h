// FontMetrics.h
// MobileTerminal
//
//

@import UIKit;
@import CoreText;

@interface FontMetrics : NSObject

- (instancetype)initWithFont:(UIFont *)font boldFont:(UIFont *)boldFont;

@property (nonatomic, strong, readonly) UIFont *regularFont;
@property (nonatomic, strong, readonly) UIFont *boldFont;

// The dimensions of a single glyph on the screen
@property (nonatomic, readonly) CGSize boundingBox;
@property (nonatomic, readonly) CGFloat descent;
@property (nonatomic, readonly) CGFloat ascent;
@property (nonatomic, readonly) CGFloat leading;

@end
