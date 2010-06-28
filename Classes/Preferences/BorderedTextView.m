// BorderedTextView.m
// MobileTerminal

#import "BorderedTextView.h"

#import <QuartzCore/QuartzCore.h>

@implementation BorderedTextView

- (void)layoutSubviews
{
  self.layer.borderColor = [[UIColor lightGrayColor] CGColor];
  self.layer.borderWidth = 1;
  self.layer.cornerRadius = 8.0;
  self.clipsToBounds = YES;
}

@end
