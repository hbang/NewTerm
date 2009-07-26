// MenuView.m
// MobileTerminal

#import "MenuView.h"
#import <QuartzCore/QuartzCore.h>


@implementation MenuView

@synthesize menuTableView;
@synthesize font;

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super initWithCoder:decoder];
  if (self != nil) {
    font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
  }
  return self;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;  
{
  return [font pointSize] * 1.5f;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  // TODO(allen): Get from preferences
  return 30;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  // This currently only supports one section
  if ([indexPath length] != 2 ||
      [indexPath indexAtPosition:0] != 0) {
    return nil;
  }
  // TODO(allen): Get the menu items from preferences
  NSString* itemTitle = [NSString stringWithFormat:@"item %d", [indexPath indexAtPosition:1]];
  UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:itemTitle];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:itemTitle];
    cell.text = itemTitle;
    cell.font = font;
  }
  return cell;
}

static const double kAnimationDuration = 0.25f;

- (void)setHidden:(BOOL)isHidden
{
  // TODO(allen): Set the max size of the view based on the total number of
  // menu items.
  if (!isHidden) {
    // When re-displaying the table, start from the top of the menu in a fresh
    // state.
    [menuTableView scrollRectToVisible:CGRectMake(0, 0, 1, 1)
                              animated:NO];
    [menuTableView deselectRowAtIndexPath:[menuTableView indexPathForSelectedRow] animated:NO];
  }
  
  [UIView beginAnimations:NULL context:NULL];
  CATransition *animation = [CATransition animation];
  [animation setDuration:kAnimationDuration];
  if (isHidden) {
    [animation setType:kCATransitionFade];
  } else {
    // Slide up the menu as it appears
    [animation setType:kCATransitionMoveIn];
    [animation setSubtype:kCATransitionFromTop];
  }
  [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];	
  [[self layer] addAnimation:animation forKey:@"toggleMenuView"];
  [super setHidden:isHidden];
  [UIView commitAnimations];  
}

@end
