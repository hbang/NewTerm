#import "HBNTTerminalSampleTableCell.h"
#import "HBNTTerminalSampleView.h"

@implementation HBNTTerminalSampleTableCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier specifier:specifier];

	if (self) {
		self.textLabel.hidden = YES;
		
		HBNTTerminalSampleView *sampleView = [[HBNTTerminalSampleView alloc] initWithFrame:self.contentView.bounds];
		sampleView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		sampleView.userInteractionEnabled = NO;
		[self.contentView addSubview:sampleView];
	}

	return self;
}

@end
