// MenuView.h
// MobileTerminal

#import <UIKit/UIKit.h>

// Displays a menu of shortcuts on the screen.  This MenuView implements the
// table data source protocol and is the delegate for the tableView.  The menu
// is laid out as a scrollable table view, sized based on the font.
// TODO(allen): The menu doesn't do anything yet.  Make it issue commands.
@interface MenuView : UIView <UITableViewDataSource> {
@private
  UITableView* menuTableView;
  UIFont* font;
}

@property (nonatomic, retain) IBOutlet UITableView *menuTableView;
@property (nonatomic, retain) IBOutlet UIFont *font;

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;  

@end
