#import "HBNTTerminalSampleViewController.h"
#import "HBNTTerminalSampleView.h"

@implementation HBNTTerminalSampleViewController

- (void)loadView {
	[super loadView];

	self.title = NSLocalizedStringFromTableInBundle(@"SAMPLE", @"Root", [NSBundle bundleForClass:self.class], @"");

	HBNTTerminalSampleView *sampleView = [[HBNTTerminalSampleView alloc] initWithFrame:self.view.bounds];
	sampleView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.view = sampleView;
}

@end
