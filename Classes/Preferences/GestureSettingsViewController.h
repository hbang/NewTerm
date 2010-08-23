// GestureSettingsViewController.h
// MobileTerminal

#import <UIKit/UIKit.h>
#import "GestureEditViewController.h"

@interface GestureSettingsViewController : UITableViewController<GestureEditDelegate> {
@private
  GestureSettings* gestureSettings;
  GestureEditViewController* gestureEditViewController;
  
  // State aboute the current item being edited in the GestureEditViewController
  BOOL editIsInsert;
}

@property(nonatomic, retain) IBOutlet GestureEditViewController* gestureEditViewController;

- (void)startEditing:(GestureItem*)gestureItem;
- (void)finishEditing:(id)sender;

@end
