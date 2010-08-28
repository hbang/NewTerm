// GestureResponder.m
// MobileTerminal

#import "GestureResponder.h"
#import "MobileTerminalViewController.h"
#import "Preferences/GestureSettings.h"
#import "Preferences/Settings.h"

@implementation GestureResponder

@synthesize viewController;

- (void)addSwipeDirection:(UISwipeGestureRecognizerDirection)direction
                   action:(SEL)action
{
  UISwipeGestureRecognizer *swipe =
    [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                              action:action];
  swipe.numberOfTouchesRequired = 1;
  swipe.direction = direction;
  UIView* view = [viewController view];
  [view addGestureRecognizer:swipe];
  [swipe release];
}

- (void)awakeFromNib
{
  UIView* view = [viewController view];
  
  gestureSettings = [[Settings sharedInstance] gestureSettings];

  UITapGestureRecognizer *singleFingerDTap =
      [[UITapGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(handleSingleDoubleTap:)];
  singleFingerDTap.numberOfTouchesRequired = 1;
  singleFingerDTap.numberOfTapsRequired = 2;
  [view addGestureRecognizer:singleFingerDTap];
  [singleFingerDTap release];

  UITapGestureRecognizer *doubleFingerDTap =
  [[UITapGestureRecognizer alloc] initWithTarget:self
                                          action:@selector(handleDoubleDoubleTap:)];
  doubleFingerDTap.numberOfTouchesRequired = 2;
  doubleFingerDTap.numberOfTapsRequired = 2;
  [view addGestureRecognizer:doubleFingerDTap];
  [doubleFingerDTap release];
  
  [self addSwipeDirection:UISwipeGestureRecognizerDirectionLeft
                   action:@selector(handleLeftSwipe:)];
  [self addSwipeDirection:UISwipeGestureRecognizerDirectionRight
                   action:@selector(handleRightSwipe:)];
  [self addSwipeDirection:UISwipeGestureRecognizerDirectionUp
                   action:@selector(handleUpSwipe:)];
  [self addSwipeDirection:UISwipeGestureRecognizerDirectionDown
                   action:@selector(handleDownSwipe:)];

  [self addSwipeDirection:(UISwipeGestureRecognizerDirectionLeft |
                           UISwipeGestureRecognizerDirectionUp)
                   action:@selector(handleLeftUpSwipe:)];
  [self addSwipeDirection:(UISwipeGestureRecognizerDirectionRight |
                           UISwipeGestureRecognizerDirectionUp)
                   action:@selector(handleRightUpSwipe:)];
  [self addSwipeDirection:(UISwipeGestureRecognizerDirectionLeft |
                           UISwipeGestureRecognizerDirectionDown)
                   action:@selector(handleLeftDownSwipe:)];
  [self addSwipeDirection:(UISwipeGestureRecognizerDirectionRight |
                           UISwipeGestureRecognizerDirectionDown)
                   action:@selector(handleRightDownSwipe:)];
}

- (void)handleAction:(NSString*)itemLabel
{
  NSLog(@"Gesture Invoked: %@", itemLabel);
  id<GestureAction> action = [gestureSettings gestureActionForItemName:itemLabel];
  [action performAction];  
}

- (IBAction)handleSingleDoubleTap:(UIGestureRecognizer*)sender {
  [self handleAction:kGestureSingleDoubleTap];
}

- (IBAction)handleDoubleDoubleTap:(UIGestureRecognizer*)sender {
  [self handleAction:kGestureDoubleDoubleTap];
}

- (IBAction)handleUpSwipe:(UIGestureRecognizer*)sender {
  [self handleAction:kGestureSwipeUp];
}

- (IBAction)handleDownSwipe:(UIGestureRecognizer*)sender {
  [self handleAction:kGestureSwipeDown];
}

- (IBAction)handleRightSwipe:(UIGestureRecognizer*)sender {
  [self handleAction:kGestureSwipeRight];
}

- (IBAction)handleLeftSwipe:(UIGestureRecognizer*)sender {
  [self handleAction:kGestureSwipeLeft];
}

- (IBAction)handleLeftUpSwipe:(UIGestureRecognizer*)sender {
  [self handleAction:kGestureSwipeLeftUp];
}

- (IBAction)handleRightUpSwipe:(UIGestureRecognizer*)sender {
  [self handleAction:kGestureSwipeRightUp];
}

- (IBAction)handleLeftDownSwipe:(UIGestureRecognizer*)sender {
  [self handleAction:kGestureSwipeLeftDown];
}

- (IBAction)handleRightDownSwipe:(UIGestureRecognizer*)sender {
  [self handleAction:kGestureSwipeRightDown];
}

@end
