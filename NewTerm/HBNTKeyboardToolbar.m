#import "HBNTKeyboardToolbar.h"
#import "HBNTKeyboardButton.h"
#import <Cephei/UIView+CompactConstraint.h>

@implementation HBNTKeyboardToolbar

- (instancetype)init {
	self = [super init];

	if (self) {
		_ctrlKey = [HBNTKeyboardButton buttonWithTitle:@"Ctrl"];
		_metaKey = [HBNTKeyboardButton buttonWithTitle:@"Esc"];
		_tabKey = [HBNTKeyboardButton buttonWithTitle:@"Tab"];

		UIView *spacerView = [[UIView alloc] init];

		for (UIView *view in @[ _ctrlKey, _metaKey, _tabKey, spacerView ]) {
			view.translatesAutoresizingMaskIntoConstraints = NO;
			[self addSubview:view];

			[self hb_addConstraintsWithVisualFormat:@"V:|-margin-[key]-margin-|" options:kNilOptions metrics:@{
				@"margin": self._isSmallDevice ? @2.f : @4.f
			} views:@{
				@"key": view
			}];
		}

		[self hb_addConstraintsWithVisualFormat:@"H:|-outerMargin-[ctrlKey]-margin-[metaKey]-margin-[tabKey][spacerView]|" options:kNilOptions metrics:@{
			@"outerMargin": @3.f,
			@"margin": @6.f
		} views:@{
			@"ctrlKey": _ctrlKey,
			@"metaKey": _metaKey,
			@"tabKey": _tabKey,
			@"spacerView": spacerView,
		}];
	}

	return self;
}

- (BOOL)_isSmallDevice {
	return [UIScreen mainScreen].bounds.size.height < 600.f;
}

- (CGSize)intrinsicContentSize {
	CGSize size = [super intrinsicContentSize];
	size.height = self._isSmallDevice ? 32.f : 44.f;
	return size;
}

@end
