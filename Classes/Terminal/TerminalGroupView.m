// TerminalGroupView.m
// MobileTerminal

#import "TerminalGroupView.h"
#import "TerminalView.h"

static const int NUM_TERMINALS = 4;

@implementation TerminalGroupView

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super initWithCoder:decoder];
  if (self != nil) {
    terminals = [[NSMutableArray alloc] init];    
    for (int i = 0; i < NUM_TERMINALS; ++i) {
      TerminalView* view = [[TerminalView alloc] initWithCoder:decoder];
      // TODO(allen): Font and Colors should be configurable.
      [view setFont:[UIFont fontWithName:@"Courier" size:10.0f]];
      [terminals addObject:view];
      [self addSubview:view];
    }
    [self bringTerminalToFront:0];
  }
  return self;
}

- (void)dealloc
{
  for (int i = 0; i < [terminals count]; ++i) {
    UIView* view = [terminals objectAtIndex:i];
    [view release];
  }
  [terminals release];
  [super dealloc];
}

- (int)terminalCount
{
  return [terminals count];
}

- (TerminalView*)terminalAtIndex:(int)index
{
  return [terminals objectAtIndex:index];
}

static const NSTimeInterval kAnimationDuration = 0.50f;

- (void)bringTerminalToFront:(TerminalView*)terminalView
{
  int previousActiveTerminalIndex = activeTerminalIndex;
  for (int i = 0; i < [terminals count]; ++i) {
    TerminalView* view = [terminals objectAtIndex:i];
    if (view == terminalView) {
      activeTerminalIndex = i;
      break;
    }
  }
  UIViewAnimationTransition transition;
  if (previousActiveTerminalIndex < activeTerminalIndex) {
    transition = UIViewAnimationTransitionCurlUp;
  } else {
    transition = UIViewAnimationTransitionCurlDown;
  } 
  [UIView beginAnimations:NULL context:NULL];
  [UIView setAnimationDuration:kAnimationDuration];
  [UIView setAnimationTransition:transition forView:self cache:YES];
  [self bringSubviewToFront:terminalView];
  [UIView commitAnimations];
}

- (TerminalView*)frontTerminal
{
  return [self terminalAtIndex:activeTerminalIndex];
}

@end
