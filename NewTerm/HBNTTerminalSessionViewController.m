//
//  HBNTTerminalSessionViewController.m
//  NewTerm
//
//  Created by Adam D on 12/12/2014.
//  Copyright (c) 2014 HASHBANG Productions. All rights reserved.
//

#import "HBNTTerminalSessionViewController.h"
#import "HBNTTerminalController.h"
#import "HBNTTerminalKeyInput.h"
#import "HBNTTerminalTextView.h"
#import "HBNTHUDView.h"
#import "HBNTPreferences.h"
#import "HBNTRootViewController.h"
#import "VT100ColorMap.h"
#import "FontMetrics.h"
#import <Cephei/UIView+CompactConstraint.h>

@implementation HBNTTerminalSessionViewController {
	HBNTTerminalController *_terminalController;
	HBNTTerminalKeyInput *_keyInput;
	HBNTTerminalTextView *_textView;
	HBNTHUDView *_bellHUDView;

	NSException *_failureException;

	BOOL _hasAppeared;
	BOOL _hasStarted;
	UIEdgeInsets _contentInset;
	CGFloat _keyboardHeight;
	CGPoint _lastAutomaticScrollOffset;
}

- (instancetype)init {
	self = [super init];

	if (self) {
		_terminalController = [[HBNTTerminalController alloc] init];
		_terminalController.viewController = self;
		_terminalController.delegate = self;

		@try {
			[_terminalController startSubProcess];
			_hasStarted = YES;
		} @catch (NSException *exception) {
			_failureException = exception;
		}
	}

	return self;
}

- (void)loadView {
	[super loadView];

	self.title = NSLocalizedString(@"TERMINAL", @"Generic title displayed before the terminal sets a proper title.");

	_textView = [[HBNTTerminalTextView alloc] initWithFrame:self.view.bounds];
	_textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_textView.showsVerticalScrollIndicator = NO;
	// TODO: this breaks stuff sorta
	// [_textView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTextViewTap:)]];
	[self.view addSubview:_textView];

	_keyInput = [[HBNTTerminalKeyInput alloc] init];
	_keyInput.textView = _textView;
	_keyInput.terminalInputDelegate = _terminalController;
	[self.view addSubview:_keyInput];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[self registerForKeyboardNotifications];
	[self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	[self resignFirstResponder];
	[self unregisterForKeyboardNotifications];
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
	[self updateScreenSize];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	if (_failureException) {
		NSString *ok = NSLocalizedStringFromTableInBundle(@"OK", @"Localizable", [NSBundle bundleForClass:UIView.class], nil);

		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"TERMINAL_LAUNCH_FAILED", @"Alert title displayed when a terminal could not be launched.") message:_failureException.reason delegate:nil cancelButtonTitle:ok otherButtonTitles:nil];
		[alertView show];
	}
}

- (void)removeFromParentViewController {
	if (_hasStarted) {
		// TODO: for some reason this always throws “subprocess was never started”? groannnn
		// [_terminalController stopSubProcess];
	}

	[super removeFromParentViewController];
}

#pragma mark - Screen

- (UIEdgeInsets)contentInset {
#ifdef __IPHONE_11_0
	if (@available(iOS 11.0, *)) {
		return self.additionalSafeAreaInsets;
	}
#endif

	return _contentInset;
}

- (void)setContentInset:(UIEdgeInsets)contentInset {
#ifdef __IPHONE_11_0
	if (@available(iOS 11.0, *)) {
		self.additionalSafeAreaInsets = contentInset;
		return;
	}
#endif

	_contentInset = contentInset;
}

- (void)updateScreenSize {
	// update the text view insets. if the keyboard height is non-zero, keyboard is visible and that’s
	// our bottom inset. else, it’s not and the bottom toolbar height is the bottom inset
	UIEdgeInsets barInsets = self.contentInset;
	barInsets.bottom = _keyboardHeight ?: barInsets.bottom;

	HBLogDebug(@"inset orig %@ new %@ keyboard %f", NSStringFromUIEdgeInsets(self.contentInset), NSStringFromUIEdgeInsets(barInsets), _keyboardHeight);

#ifdef __IPHONE_11_0
	if (@available(iOS 11.0, *)) {
		barInsets.top -= self.view.safeAreaInsets.top;
		barInsets.bottom -= self.view.safeAreaInsets.bottom;
	}
#endif

	_textView.contentInset = barInsets;
	_textView.scrollIndicatorInsets = _textView.contentInset;

	CGSize glyphSize = _terminalController.fontMetrics.boundingBox;

	// Determine the screen size based on the font size
	CGFloat width = _textView.frame.size.width - barInsets.left - barInsets.right;
	CGFloat height = _textView.frame.size.height - barInsets.top - barInsets.bottom;

	ScreenSize size;
	size.width = floorf(width / glyphSize.width);
	size.height = floorf(height / glyphSize.height);

	// The font size should not be too small that it overflows the glyph buffers. It is not worth the
	// effort to fail gracefully (increasing the buffer size would be better).
	NSParameterAssert(size.width < kMaxRowBufferSize);

	if (size.width != _terminalController.screenSize.width || size.height != _terminalController.screenSize.height) {
		_terminalController.screenSize = size;
	}
}

- (void)refreshWithAttributedString:(NSAttributedString *)attributedString backgroundColor:(UIColor *)backgroundColor {
	_textView.attributedText = attributedString;

	if (backgroundColor != _textView.backgroundColor) {
		_textView.backgroundColor = backgroundColor;
	}

	// TODO: not sure why this is needed all of a sudden? what did i break?
	dispatch_async(dispatch_get_main_queue(), ^{
		[self scrollToBottom];
	});
}

- (void)activateBell {
	// display the bell HUD, lazily initialising it if it hasn’t been yet
	if (!_bellHUDView) {
		_bellHUDView = [[HBNTHUDView alloc] initWithImage:[UIImage imageNamed:@"bell-hud"]];
		_bellHUDView.translatesAutoresizingMaskIntoConstraints = NO;
		[self.view addSubview:_bellHUDView];
		[self.view hb_addCompactConstraints:@[
			@"hudView.centerX = self.centerX",
			@"hudView.top = self.top + 100"
		] metrics:nil views:@{
			@"self": self.view,
			@"hudView": _bellHUDView
		}];
	}

	[_bellHUDView animate];
}

- (void)close {
	// TODO: i guess this is kind of the wrong spot
	if (self.parentViewController && self.parentViewController.class == HBNTRootViewController.class) {
		[(HBNTRootViewController *)self.parentViewController removeTerminal:self];
	}
}

- (void)scrollToBottom {
	// if the user has scrolled up far enough on their own, don’t rudely scroll them back to the
	// bottom. when they scroll back, the automatic scrolling will continue
	// TODO: buggy
	// if (_textView.contentOffset.y < _lastAutomaticScrollOffset.y - 20) {
	// 	return;
	// }
	
	CGFloat originalY = _textView.contentOffset.y;
	[_textView scrollRectToVisible:CGRectMake(0, _terminalController.scrollbackLines == 0 ? 0 : _textView.contentSize.height - 1, _textView.contentSize.width, 1) animated:NO];

	if (_textView.contentOffset.y != originalY) {
		_lastAutomaticScrollOffset = _textView.contentOffset;
	}
}

#pragma mark - Keyboard management

- (void)registerForKeyboardNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardVisibilityChanged:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardVisibilityChanged:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)unregisterForKeyboardNotifications {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardVisibilityChanged:(NSNotification *)notification {
	// we do this to avoid the scroll indicator from appearing as soon as the terminal appears. we
	// only want to see it after the keyboard has appeared
	if (!_hasAppeared) {
		_hasAppeared = YES;
		_textView.showsVerticalScrollIndicator = YES;
	}

	// YES when showing, NO when hiding
	BOOL direction = [notification.name isEqualToString:UIKeyboardWillShowNotification];

	CGFloat animationDuration = ((NSNumber *)notification.userInfo[UIKeyboardAnimationDurationUserInfoKey]).doubleValue;

	// determine the final keyboard height. we still get a height if hiding, so force it to 0 if this
	// isn’t a show notification
	CGRect keyboardFrame = ((NSValue *)notification.userInfo[UIKeyboardFrameEndUserInfoKey]).CGRectValue;
	_keyboardHeight = direction ? keyboardFrame.size.height : 0;

	// we call updateScreenSize in an animation block to force it to be animated with the exact
	// parameters given to us in the notification
	[UIView animateWithDuration:animationDuration animations:^{
		[self updateScreenSize];
	}];
}

- (BOOL)becomeFirstResponder {
	return [_keyInput becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
	return [_keyInput resignFirstResponder];
}

- (BOOL)isFirstResponder {
	return _keyInput.isFirstResponder;
}

- (void)toggleKeyboard:(id)sender {
	if (self.isFirstResponder) {
		[self resignFirstResponder];
	} else {
		[self becomeFirstResponder];
	}
}

- (void)handleTextViewTap:(UITapGestureRecognizer *)gestureRecognizer {
	if (gestureRecognizer.state == UIGestureRecognizerStateEnded && !self.isFirstResponder) {
		[self becomeFirstResponder];
	}
}

@end
