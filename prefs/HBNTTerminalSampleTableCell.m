#import "HBNTTerminalSampleTableCell.h"
#import "HBNTTerminalSampleView.h"
#import <version.h>

@implementation HBNTTerminalSampleTableCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier specifier:specifier];

	if (self) {
		self.textLabel.hidden = YES;
		
		HBNTTerminalSampleView *sampleView = [[HBNTTerminalSampleView alloc] initWithFrame:self.contentView.bounds];
		sampleView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		sampleView.userInteractionEnabled = NO;

		if (!IS_IOS_OR_NEWER(iOS_7_0)) {
			sampleView.clipsToBounds = YES;
			sampleView.layer.cornerRadius = 8.f;
		}

		[self.contentView addSubview:sampleView];
	}

	return self;
}

@end
