// AboutViewController.m
// MobileTerminal

#import "AboutViewController.h"
#import "svnversion.h"

@implementation AboutViewController

@synthesize versionLabel;

- (void)awakeFromNib
{
  [super awakeFromNib];
  versionLabel.text = [NSString stringWithFormat:@"r%d", SVN_VERSION];
}

@end
