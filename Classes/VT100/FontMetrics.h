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
@property (readonly) CTFontRef ctFont;

// The dimensions of a single glyph on the screen
@property (readonly) CGSize boundingBox;
@property (readonly) float descent;
@property (readonly) float ascent;
@property (readonly) float leading;

@end
