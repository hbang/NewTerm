// MobileTerminalViewController.h
// MobileTerminal

#import <UIKit/UIKit.h>
#import "MenuView.h"

@class TerminalGroupView;
@class TerminalKeyboard;
@class GestureResponder;
@class GestureActionRegistry;

// Protocol to get notified about when the preferences button is pressed.
// TOOD(allen): We should find a better way to do this.
@protocol MobileTerminalInterfaceDelegate
@required
- (void)preferencesButtonPressed;
- (void)rootViewDidAppear;
@end

@interface MobileTerminalViewController : UIViewController // <MenuViewDelegate>

@property (nonatomic, retain) UIButton *preferencesButton;
@property (nonatomic, retain) id<MobileTerminalInterfaceDelegate> interfaceDelegate;
@property (nonatomic, retain) GestureResponder *gestureResponder;
@property (nonatomic, retain) GestureActionRegistry *gestureActionRegistry;

@end

