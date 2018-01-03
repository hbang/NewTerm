//
//  HBNTTerminalSessionViewController.m
//  NewTerm
//
//  Created by Adam D on 12/12/2014.
//  Copyright (c) 2014 HASHBANG Productions. All rights reserved.
//

#import "HBNTTerminalSessionViewController.h"
#import "HBNTTerminalController.h"
#import "HBNTTerminalTextView.h"
#import "HBNTPreferences.h"
#import "HBNTRootViewController.h"
#import "VT100ColorMap.h"
#import "FontMetrics.h"

@implementation HBNTTerminalSessionViewController {
	HBNTTerminalController *_terminalController;
	HBNTTerminalTextView *_textView;

	NSException *_failureException;

	BOOL _hasAppeared;
	CGFloat _keyboardHeight;
	CGPoint _lastAutomaticScrollOffset;
}

- (instancetype)init {
	self = [super init];

	if (self) {
		self.automaticallyAdjustsScrollViewInsets = NO;

		_terminalController = [[HBNTTerminalController alloc] init];
		_terminalController.viewController = self;
		_terminalController.delegate = self;

		@try {
			[_terminalController startSubProcess];
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
	_textView.terminalInputDelegate = _terminalController;
	[self.view addSubview:_textView];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[self registerForKeyboardNotifications];
	[self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	[self unregisterForKeyboardNotifications];
	[self resignFirstResponder];
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
	[self updateScreenSize];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	if (_failureException) {
		NSString *ok = NSLocalizedStringFromTableInBundle(@"OK", @"Localizable", [NSBundle bundleForClass:UIView.class], nil);

		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"TERMINAL_LAUNCH_FAILED", @"Alert title displayed when a terminal could not be launched.") message:_failureException.reason preferredStyle:UIAlertControllerStyleAlert];
		[alertController addAction:[UIAlertAction actionWithTitle:ok style:UIAlertActionStyleCancel handler:nil]];
		[self.navigationController presentViewController:alertController animated:YES completion:nil];
	}
}

#pragma mark - Screen

- (void)updateScreenSize {
	// update the text view insets. if the keyboard height is non-zero, keyboard is visible and that’s
	// our bottom inset. else, it’s not and the bottom toolbar height is the bottom inset
	UIEdgeInsets barInsets = _barInsets;
	barInsets.bottom = _keyboardHeight ?: barInsets.bottom;

	_textView.contentInset = _barInsets;
	_textView.scrollIndicatorInsets = _textView.contentInset;

	CGSize glyphSize = _terminalController.fontMetrics.boundingBox;

	// Determine the screen size based on the font size
	CGFloat width = _textView.frame.size.width;
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

	[self scrollToBottomWithInsets:_textView.scrollIndicatorInsets];
}

- (void)scrollToBottomWithInsets:(UIEdgeInsets)inset {
	// if the user has scrolled up far enough on their own, don’t rudely scroll them back to the
	// bottom. when they scroll back, the automatic scrolling will continue
	if (_textView.contentOffset.y < _lastAutomaticScrollOffset.y - 20) {
		return;
	}
	
	// if there is no scrollback, use the top of the scroll view. if there is, calculate the bottom
	CGPoint offset = _textView.contentOffset;
	CGFloat bottom = _keyboardHeight ?: inset.bottom;
	offset.y = _terminalController.scrollbackLines == 0 ? -inset.top : bottom + _textView.contentSize.height - _textView.frame.size.height;

	// if the offset has changed, update it and our lastAutomaticScrollOffset
	if (_textView.contentOffset.y != offset.y) {
		_textView.contentOffset = offset;
		_lastAutomaticScrollOffset = offset;
	}
}

- (void)close {
	// TODO: i guess this is kind of the wrong spot
	if (self.parentViewController && self.parentViewController.class == HBNTRootViewController.class) {
		[(HBNTRootViewController *)self.parentViewController removeTerminal:self];
	}
}

#pragma mark - Keyboard management

- (void)registerForKeyboardNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardVisibilityChanged:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardVisibilityChanged:) name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateScreenSize) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateScreenSize) name:UIKeyboardDidHideNotification object:nil];
}

- (void)unregisterForKeyboardNotifications {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
}

- (void)keyboardVisibilityChanged:(NSNotification *)notification {
	if (!_hasAppeared) {
		_hasAppeared = YES;
		_textView.showsVerticalScrollIndicator = YES;
	}

	CGRect keyboardFrame = ((NSValue *)notification.userInfo[UIKeyboardFrameEndUserInfoKey]).CGRectValue;
	_keyboardHeight = keyboardFrame.size.height;

	// we call updateScreenSize in an animation block to force it to be animated with the exact
	// parameters given to us in the notification
	[UIView animateWithDuration:((NSNumber *)notification.userInfo[UIKeyboardAnimationDurationUserInfoKey]).doubleValue animations:^{
		[self updateScreenSize];
	}];
}

- (BOOL)becomeFirstResponder {
	return [_textView becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
	return [_textView resignFirstResponder];
}

- (BOOL)isFirstResponder {
	return _textView.isFirstResponder;
}

- (void)toggleKeyboard:(id)sender {
	if (self.isFirstResponder) {
		[self resignFirstResponder];
	} else {
		[self becomeFirstResponder];
	}
}

@end
