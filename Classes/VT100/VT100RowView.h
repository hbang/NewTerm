// VT100RowView.h
// MobileTerminal
//
// A single row of text of the terminal.

#import <UIKit/UIKit.h>

@protocol AttributedStringSupplier;
@class FontMetrics;

@interface VT100RowView : UIView {
@private
  //int rowIndex;
  FontMetrics* fontMetrics;
  id<AttributedStringSupplier> stringSupplier;
}

@property (nonatomic) int rowIndex;
@property (nonatomic, retain) id<AttributedStringSupplier> stringSupplier;
@property (nonatomic, retain) FontMetrics* fontMetrics;

@end
