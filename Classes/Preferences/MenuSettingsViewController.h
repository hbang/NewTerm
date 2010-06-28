// MenuSettingsViewController.h
// MobileTerminal

#import <UIKit/UIKit.h>
#import "MenuEditViewController.h"

@class MenuItem;
@class MenuSettings;

// Displays the list of menu items, providing a UI for adding new items,
// deleting old items, and editing existing items.
@interface MenuSettingsViewController : UITableViewController <MenuEditDelegate> {
@private
  MenuSettings* menuSettings;
  MenuEditViewController* menuEditViewController;
  
  // State aboute the current item being edited in the MenuEditViewController
  BOOL editIsInsert;
}

@property(nonatomic, retain) IBOutlet MenuEditViewController* menuEditViewController;

- (void)startEditing:(MenuItem*)menuItem asInsert:(BOOL)isInsert;
- (void)finishEditing:(id)sender;

@end
