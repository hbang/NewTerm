// ColorMap.h
// MobileTerminal

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define COLOR_MAP_MAX_COLORS 16

@interface ColorMap : NSObject <NSCoding> {
@private
  UIColor* table[COLOR_MAP_MAX_COLORS];
  UIColor* background;
  UIColor* foreground;
  UIColor* foregroundBold;
  UIColor* foregroundCursor;
  UIColor* backgroundCursor;
}

@property (nonatomic, retain) UIColor* background;
@property (nonatomic, retain) UIColor* foreground;
@property (nonatomic, retain) UIColor* foregroundBold;
@property (nonatomic, retain) UIColor* foregroundCursor;
@property (nonatomic, retain) UIColor* backgroundCursor;

- (id)init;
- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;

// Terminal color index
- (UIColor*) color:(unsigned int)index;

@end
