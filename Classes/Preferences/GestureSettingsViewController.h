// GestureSettingsViewController.h
// MobileTerminal

#import <UIKit/UIKit.h>
#import "GestureEditViewController.h"

@interface GestureSettingsViewController : UITableViewController<GestureEditDelegate> {
@private
  GestureSettings* gestureSettings;
  GestureEditViewController* gestureEditViewController;
}

@property(nonatomic, retain) IBOutlet GestureEditViewController* gestureEditViewController;

- (void)startEditing:(GestureItem*)gestureItem;
- (void)finishEditing:(id)sender;

@end
