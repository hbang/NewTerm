// ColorMap.h
// MobileTerminal

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define COLOR_MAP_MAX_COLORS 16

@interface ColorMap : NSObject

@property (nonatomic, retain) UIColor *background;
@property (nonatomic, retain) UIColor *foreground;
@property (nonatomic, retain) UIColor *foregroundBold;
@property (nonatomic, retain) UIColor *foregroundCursor;
@property (nonatomic, retain) UIColor *backgroundCursor;

- (instancetype)init;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

// Terminal color index
- (UIColor *)colorAtIndex:(unsigned)index;

@end
