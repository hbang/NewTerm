// VT100TableViewController.h
// MobileTerminal


#import <UIKit/UIKit.h>

@class ColorMap;
@class FontMetrics;
@protocol AttributedStringSupplier;

@interface VT100TableViewController : UITableViewController {
@private
  ColorMap* colorMap;
  FontMetrics* fontMetrics;
  id<AttributedStringSupplier> stringSupplier;
}

- (id)initWithColorMap:(ColorMap*)colorMap;

@property (nonatomic, retain) FontMetrics* fontMetrics;
@property (nonatomic, retain) id<AttributedStringSupplier> stringSupplier;

- (void)refresh;

@end
