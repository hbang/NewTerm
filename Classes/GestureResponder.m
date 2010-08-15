// GestureResponder.m
// MobileTerminal

#import "GestureResponder.h"
#import "MobileTerminalViewController.h"

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

- (IBAction)handleSingleDoubleTap:(UIGestureRecognizer*)sender {
  NSLog(@"single double tap");
  // TODO(allen): Make configurable
  [viewController toggleKeyboard];
}

- (IBAction)handleDoubleDoubleTap:(UIGestureRecognizer*)sender {
  NSLog(@"double double tap");
}

- (IBAction)handleUpSwipe:(UIGestureRecognizer*)sender {
  NSLog(@"single up swipe");
}

- (IBAction)handleDownSwipe:(UIGestureRecognizer*)sender {
  NSLog(@"single down swipe");
}

- (IBAction)handleRightSwipe:(UIGestureRecognizer*)sender {
  NSLog(@"single right swipe");
}

- (IBAction)handleLeftSwipe:(UIGestureRecognizer*)sender {
  NSLog(@"single left swipe");
}

- (IBAction)handleLeftUpSwipe:(UIGestureRecognizer*)sender {
  NSLog(@"single left up swipe");
}

- (IBAction)handleRightUpSwipe:(UIGestureRecognizer*)sender {
  NSLog(@"single right up swipe");
}

- (IBAction)handleLeftDownSwipe:(UIGestureRecognizer*)sender {
  NSLog(@"single left down swipe");
}

- (IBAction)handleRightDownSwipe:(UIGestureRecognizer*)sender {
  NSLog(@"single right down swipe");
}

@end
