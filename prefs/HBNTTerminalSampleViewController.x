#import "HBNTTerminalSampleViewController.h"

@interface TerminalSampleView : UIView

@end

@implementation HBNTTerminalSampleViewController

- (void)loadView {
	[super loadView];

	self.title = NSLocalizedStringFromTableInBundle(@"SAMPLE", @"Root", [NSBundle bundleForClass:self.class], @"");

	TerminalSampleView *sampleView = [[%c(TerminalSampleView) alloc] initWithFrame:self.view.bounds];
	sampleView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.view = sampleView;
}

@end
