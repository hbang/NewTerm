// ColorMap.h
// MobileTerminal

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// 16 terminal color slots available
#define COLOR_MAP_MAX_COLORS 16

@interface VT100ColorMap : NSObject

@property (nonatomic, retain, readonly) UIColor *background;
@property (nonatomic, retain, readonly) UIColor *foreground;
@property (nonatomic, retain, readonly) UIColor *foregroundBold;
@property (nonatomic, retain, readonly) UIColor *foregroundCursor;
@property (nonatomic, retain, readonly) UIColor *backgroundCursor;

@property (nonatomic, readonly) BOOL isDark;

- (instancetype)init;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

// Terminal color index
- (UIColor *)colorAtIndex:(unsigned)index;

@end
