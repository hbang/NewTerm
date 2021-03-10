// ColorMap.h
// MobileTerminal

#import "CrossPlatformUI.h"

// 16 terminal color slots available
#define COLOR_MAP_MAX_COLORS 16

@interface VT100ColorMap : NSObject

@property (nonatomic, retain, readonly) Color *background;
@property (nonatomic, retain, readonly) Color *foreground;
@property (nonatomic, retain, readonly) Color *foregroundBold;
@property (nonatomic, retain, readonly) Color *foregroundCursor;
@property (nonatomic, retain, readonly) Color *backgroundCursor;

@property (nonatomic, readonly) BOOL isDark;

#if TARGET_OS_IPHONE
@property (nonatomic, readonly) UIUserInterfaceStyle userInterfaceStyle;
#else
@property (nonatomic, readonly) NSAppearanceName appearanceStyle;
#endif

- (instancetype)init;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

// Terminal color index
- (Color *)colorAtIndex:(unsigned)index;

@end
