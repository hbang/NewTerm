// FontMetrics.h
// MobileTerminal
//
//

#import <CoreText/CoreText.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIFont.h>

@interface FontMetrics : NSObject

- (instancetype)initWithFont:(UIFont *)font;

@property (nonatomic, retain, readonly) UIFont *font;

// The dimensions of a single glyph on the screen
@property (readonly) CGSize boundingBox;
@property (readonly) CGFloat descent;
@property (readonly) CGFloat ascent;
@property (readonly) CGFloat leading;

@end
