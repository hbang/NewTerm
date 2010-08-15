// GestureResponder.h
// MobileTerminal

#import <Foundation/Foundation.h>

@class MobileTerminalViewController;

@interface GestureResponder : NSObject {
@private
  MobileTerminalViewController* viewController;
}

@property (nonatomic, retain) IBOutlet MobileTerminalViewController *viewController;

@end
