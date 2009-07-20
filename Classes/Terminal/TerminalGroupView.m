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

- (void)bringTerminalToFront:(TerminalView*)terminalView
{
  for (int i = 0; i < [terminals count]; ++i) {
    TerminalView* view = [terminals objectAtIndex:i];
    if (view == terminalView) {
      activeTerminalIndex = i;
      break;
    }
  }
  // TODO(allen): It would be nice if this was an animated change.
  [self bringSubviewToFront:terminalView];
}

- (TerminalView*)frontTerminal
{
  return [self terminalAtIndex:activeTerminalIndex];
}

@end
