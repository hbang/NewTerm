#import "HBNTTabToolbar.h"
#import "HBNTTabCollectionViewCell.h"

@implementation HBNTTabToolbar

- (instancetype)init {
	self = [super init];

	if (self) {
		UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
		collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
		collectionViewLayout.minimumInteritemSpacing = 0;
		collectionViewLayout.estimatedItemSize = CGSizeMake(100, 44);

		_tabsCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:collectionViewLayout];
		_tabsCollectionView.backgroundColor = nil;
		[self addSubview:_tabsCollectionView];

		[_tabsCollectionView registerClass:HBNTTabCollectionViewCell.class forCellWithReuseIdentifier:@"TabCell"];

		_addButton = [UIButton buttonWithType:UIButtonTypeSystem];
		_addButton.titleLabel.font = [UIFont systemFontOfSize:18.f];
		[_addButton setTitle:@"＋" forState:UIControlStateNormal];
		_addButton.accessibilityLabel = NSLocalizedString(@"NEW_TAB", @"VoiceOver label for the new tab button.");
		[self addSubview:_addButton];

		CGFloat shadowHeight = 1 / [UIScreen mainScreen].scale;
		UIView *shadowView = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - shadowHeight, self.frame.size.width, shadowHeight)];
		shadowView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
		shadowView.backgroundColor = [UIColor colorWithWhite:38.f / 255.f alpha:1];
		[self addSubview:shadowView];
	}

	return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)_tabsCollectionView.collectionViewLayout;

	CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
	CGFloat addButtonWidth = 44.f;

	_addButton.frame = CGRectMake(self.frame.size.width - addButtonWidth, statusBarHeight, addButtonWidth, self.frame.size.height - statusBarHeight);
	collectionViewLayout.estimatedItemSize = CGSizeMake(100, _addButton.frame.size.height);
	_tabsCollectionView.frame = CGRectMake(0, statusBarHeight, _addButton.frame.origin.x, collectionViewLayout.estimatedItemSize.height);

	CGFloat newButtonSize = _addButton.frame.size.height < 44.f ? 18.f : 24.f;
	
	if (_addButton.titleLabel.font.pointSize != newButtonSize) {
		_addButton.titleLabel.font = [UIFont systemFontOfSize:newButtonSize];
	}
}

@end
