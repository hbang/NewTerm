// AboutViewController.m
// MobileTerminal

#import "AboutViewController.h"
#import "Settings.h"

@implementation AboutViewController

@synthesize versionLabel;

- (void)awakeFromNib {
	[super awakeFromNib];
	versionLabel.text = [NSString stringWithFormat:@"Version %@", [[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleShortVersionString"]];
}

@end
