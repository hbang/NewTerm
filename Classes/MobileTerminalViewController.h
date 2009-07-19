// MobileTerminalViewController.h
// MobileTerminal

#import <UIKit/UIKit.h>

@class TerminalGroupView;
@class TerminalKeyboard;

@interface MobileTerminalViewController : UIViewController {
@private
  UIView* contentView;
  TerminalGroupView* terminalGroupView;
  UIPageControl* terminalSelector;
  TerminalKeyboard* terminalKeyboard;
  BOOL keyboardShown;
}

@property (nonatomic, retain) IBOutlet UIView* contentView;
@property (nonatomic, retain) IBOutlet TerminalGroupView* terminalGroupView;
@property (nonatomic, retain) IBOutlet UIPageControl* terminalSelector;

@end

