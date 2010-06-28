// MenuItemEditor.h
// MobileTerminal

#import <UIKit/UIKit.h>

@class MenuItem;

// Invoked when the user completes editing. 
@protocol MenuEditDelegate
- (void)finishEditing:(id)sender;
@end

// Before invoking the controller, the caller should assign an editingMenuItem
// and a menuEditDelegate that will be invoked if editing is completed
// and the user wanted to save their actions.  If the user clicks cancel the
// delegate is not invoked.
@interface MenuEditViewController : UIViewController {
@private
  UITextField* labelTextField;
  UITextView* commandTextView;
  MenuItem* editingMenuItem;
  id<MenuEditDelegate> menuEditDelegate;
}

@property(nonatomic, retain) IBOutlet UITextField* labelTextField;
@property(nonatomic, retain) IBOutlet UITextView* commandTextView;

@property(nonatomic, retain) IBOutlet MenuItem* editingMenuItem;
@property(nonatomic, retain) IBOutlet id<MenuEditDelegate> menuEditDelegate;

@end
