#import "HBNTTabToolbar.h"
#import "HBNTTabCollectionViewCell.h"
#import <version.h>

@implementation HBNTTabToolbar

- (instancetype)init {
	self = [super init];

	if (self) {
		UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
		collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
		collectionViewLayout.minimumInteritemSpacing = 0;
		collectionViewLayout.minimumLineSpacing = 0;

		// the weird frame is to appease ios 6 UICollectionView
		_tabsCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 100, 100) collectionViewLayout:collectionViewLayout];
		_tabsCollectionView.backgroundColor = nil;
		_tabsCollectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
		_tabsCollectionView.allowsMultipleSelection = NO;
		[self addSubview:_tabsCollectionView];

		[_tabsCollectionView registerClass:HBNTTabCollectionViewCell.class forCellWithReuseIdentifier:@"TabCell"];

		// TODO: maybe this should be moved to the toolbar as a UIBarButtonItem to appease iOS 6
		_addButton = [UIButton buttonWithType:IS_IOS_OR_NEWER(iOS_7_0) ? UIButtonTypeSystem : UIButtonTypeCustom];
		_addButton.titleLabel.font = [UIFont systemFontOfSize:18.f];
		[_addButton setTitle:@"＋" forState:UIControlStateNormal];
		_addButton.accessibilityLabel = NSLocalizedString(@"NEW_TAB", @"VoiceOver label for the new tab button.");
		[self addSubview:_addButton];

		CGFloat shadowHeight = 1 / [UIScreen mainScreen].scale;
		UIView *shadowView = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - shadowHeight, self.frame.size.width, shadowHeight)];
		shadowView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
		shadowView.backgroundColor = [UIColor colorWithWhite:64.f / 255.f alpha:1];
		[self addSubview:shadowView];
	}

	return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];

	CGFloat statusBarHeight = IS_IOS_OR_NEWER(iOS_7_0) ? [UIApplication sharedApplication].statusBarFrame.size.height : 0;
	CGFloat addButtonWidth = 44.f;

	_addButton.frame = CGRectMake(self.frame.size.width - addButtonWidth, statusBarHeight, addButtonWidth, self.frame.size.height - statusBarHeight);
	_tabsCollectionView.frame = CGRectMake(0, statusBarHeight, _addButton.frame.origin.x, _addButton.frame.size.height);

	CGFloat newButtonSize = _addButton.frame.size.height < 44.f ? 18.f : 24.f;
	
	if (_addButton.titleLabel.font.pointSize != newButtonSize) {
		_addButton.titleLabel.font = [UIFont systemFontOfSize:newButtonSize];
	}
}

@end
