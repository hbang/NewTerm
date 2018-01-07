#import "HBNTTabCollectionViewCell.h"
#import <Cephei/UIView+CompactConstraint.h>

@implementation HBNTTabCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];

	if (self) {
		// self.contentView.translatesAutoresizingMaskIntoConstraints = NO;

		self.selectedBackgroundView = [[UIView alloc] init];
		self.selectedBackgroundView.backgroundColor = [UIColor colorWithWhite:85.f / 255.f alpha:0.7f];

		_textLabel = [[UILabel alloc] init];
		_textLabel.translatesAutoresizingMaskIntoConstraints = NO;
		_textLabel.font = [UIFont systemFontOfSize:16.f];
		_textLabel.textColor = [UIColor whiteColor];
		_textLabel.backgroundColor = [UIColor clearColor];
		[self.contentView addSubview:_textLabel];

		_closeButton = [[UIButton alloc] init];
		_closeButton.translatesAutoresizingMaskIntoConstraints = NO;
		_closeButton.accessibilityLabel = NSLocalizedString(@"CLOSE_TAB", @"VoiceOver label for the close tab button.");
		_closeButton.titleLabel.font = [UIFont systemFontOfSize:16.f];
		[_closeButton setTitle:@"×" forState:UIControlStateNormal];
		[self.contentView addSubview:_closeButton];

		[self.contentView hb_addCompactConstraints:@[
			@"textLabel.centerY = contentView.centerY",
			@"textLabel.left = contentView.left + 6",
			@"closeButton.width = 24",
			@"closeButton.height = contentView.height",
			@"closeButton.left = textLabel.right",
			@"closeButton.right = contentView.right"
		] metrics:@{} views:@{
			@"contentView": self.contentView,
			@"textLabel": _textLabel,
			@"closeButton": _closeButton
		}];
	}

	return self;
}

- (CGSize)intrinsicContentSize {
	CGSize size = [super intrinsicContentSize];
	size.height = [UIScreen mainScreen].bounds.size.height < 600 ? 32.f : 40.f;
	return size;
}

@end
