// MobileTerminalViewController.h
// MobileTerminal

#import <UIKit/UIKit.h>
#import "MenuView.h"

@class TerminalGroupView;
@class TerminalKeyboard;
@class GestureResponder;
@class GestureActionRegistry;

@interface MobileTerminalViewController : UIViewController <UIPopoverControllerDelegate> // <MenuViewDelegate>

@property (nonatomic, retain) UIButton *preferencesButton;
@property (nonatomic, retain) GestureResponder *gestureResponder;
@property (nonatomic, retain) GestureActionRegistry *gestureActionRegistry;

@end

