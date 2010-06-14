// MenuView.h
// MobileTerminal

#import <UIKit/UIKit.h>

@class MenuSettings;

// Delegate protocol for getting notified when a menu item is pressed, meaning
// that the user wishes to invoke the specified command.
@protocol MenuViewDelegate
@required
- (void)selectedCommand:(NSString*)command;
@end

// Displays a menu of shortcuts on the screen.  This MenuView implements the
// table data source protocol and is the delegate for the tableView.  The menu
// is laid out as a scrollable table view, sized based on the font.
@interface MenuView : UIView <UITableViewDataSource> {
@private
  UITableView* menuTableView;
  UIFont* font;
  MenuSettings* menuSettings;
  id<MenuViewDelegate> delegate;
}

@property (nonatomic, retain) IBOutlet UITableView *menuTableView;
@property (nonatomic, retain) IBOutlet UIFont *font;
@property (nonatomic, retain) IBOutlet MenuSettings *menuSettings;
@property (nonatomic, retain) IBOutlet id<MenuViewDelegate> delegate;

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;  

@end
