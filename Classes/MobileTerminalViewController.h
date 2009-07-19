// MobileTerminalViewController.h
// MobileTerminal

#import <UIKit/UIKit.h>

@class TerminalKeyboard;
@class TerminalView;

@interface MobileTerminalViewController : UIViewController {
@private
  UIView* contentView;
  TerminalView *terminalView;
  TerminalKeyboard* terminalKeyboard;
  BOOL keyboardShown;
}

@property (nonatomic, retain) IBOutlet UIView *contentView;
@property (nonatomic, retain) IBOutlet TerminalView *terminalView;

@end

