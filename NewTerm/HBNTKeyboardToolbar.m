#import "HBNTKeyboardToolbar.h"
#import "HBNTKeyboardButton.h"
#import <Cephei/UIView+CompactConstraint.h>

@interface HBNTKeyboardToolbar () <UIInputViewAudioFeedback>

@end

@implementation HBNTKeyboardToolbar

- (instancetype)init {
	self = [super init];

	if (self) {
		UIView *toolbar = [[UIToolbar alloc] initWithFrame:self.bounds];
		toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self addSubview:toolbar];

		_ctrlKey = [HBNTKeyboardButton buttonWithTitle:@"Ctrl"];
		_metaKey = [HBNTKeyboardButton buttonWithTitle:@"Esc"];
		_tabKey = [HBNTKeyboardButton buttonWithTitle:@"Tab"];

		UIView *spacerView = [[UIView alloc] init];

		_upKey = [HBNTKeyboardButton buttonWithTitle:@"▲"];
		_downKey = [HBNTKeyboardButton buttonWithTitle:@"▼"];
		_leftKey = [HBNTKeyboardButton buttonWithTitle:@"◀"];
		_rightKey = [HBNTKeyboardButton buttonWithTitle:@"▶"];

		for (UIView *view in @[ _ctrlKey, _metaKey, _tabKey, spacerView, _upKey, _downKey, _leftKey, _rightKey ]) {
			view.translatesAutoresizingMaskIntoConstraints = NO;
			[self addSubview:view];

			[self hb_addConstraintsWithVisualFormat:@"V:|-margin-[key]-margin-|" options:kNilOptions metrics:@{
				@"margin": self._isSmallDevice ? @2.f : @4.f
			} views:@{
				@"key": view
			}];
		}

		[self hb_addConstraintsWithVisualFormat:@"H:|-outerMargin-[ctrlKey]-margin-[metaKey]-margin-[tabKey][spacerView(>=margin)][_upKey]-margin-[_downKey]-margin-[_leftKey]-margin-[_rightKey]-outerMargin-|" options:kNilOptions metrics:@{
			@"outerMargin": @3.f,
			@"margin": @6.f
		} views:@{
			@"ctrlKey": _ctrlKey,
			@"metaKey": _metaKey,
			@"tabKey": _tabKey,
			@"spacerView": spacerView,
			@"_upKey": _upKey,
			@"_downKey": _downKey,
			@"_leftKey": _leftKey,
			@"_rightKey": _rightKey,
		}];
	}

	return self;
}

- (BOOL)enableInputClicksWhenVisible {
	// conforming to <UIInputViewAudioFeedback> allows the buttons to make the click sound when tapped
	return YES;
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
