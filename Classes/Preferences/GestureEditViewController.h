// GestureEditViewController.h
// MobileTerminal

#import <UIKit/UIKit.h>
#import "GestureSettings.h"

// Invoked when the user completes editing. 
@protocol GestureEditDelegate
- (void)finishEditing:(id)sender;
@end

@interface GestureEditViewController : UIViewController<UIPickerViewDelegate, UIPickerViewDataSource> {
@private
  GestureSettings* settings;
  
  UILabel* gestureLabel;
  UIPickerView* actionPicker;
  GestureItem* editingGestureItem;
  id<GestureEditDelegate> gestureEditDelegate;
  
  int selectedRow;
}

@property(nonatomic, retain) IBOutlet UILabel* gestureLabel;
@property(nonatomic, retain) IBOutlet UIPickerView* actionPicker;

@property(nonatomic, retain) GestureItem* editingGestureItem;
@property(nonatomic, retain) id<GestureEditDelegate> gestureEditDelegate;

@end
