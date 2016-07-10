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
#import "VT100.h"
#import "VT100StringSupplier.h"
#import "VT100ColorMap.h"
#import "FontMetrics.h"

// TODO: a lot of this probably shouldn't be here...

@implementation HBNTTerminalSessionViewController {
	HBNTTerminalTextView *_textView;
	NSMutableAttributedString *_attributedString;

	VT100 *_buffer;
	VT100StringSupplier *_stringSupplier;
	VT100ColorMap *_colorMap;
	FontMetrics *_fontMetrics;
	HBNTTerminalController *_terminalController;

	BOOL _hasAppeared;
	BOOL _keyboardVisible;
	BOOL _launchFailed;
}

- (instancetype)init {
	self = [super init];

	if (self) {
		_buffer = [[VT100 alloc] init];
		_buffer.refreshDelegate = self;

		_stringSupplier = [[VT100StringSupplier alloc] init];
		_stringSupplier.colorMap = [[VT100ColorMap alloc] init];
		_stringSupplier.screenBuffer = _buffer;

		_terminalController = [[HBNTTerminalController alloc] init];
		_terminalController.viewController = self;

		[self preferencesUpdated];

		@try {
			[_terminalController startSubProcess];
		} @catch (NSException *exception) {
			_launchFailed = YES;
		}
	}

	return self;
}

- (void)loadView {
	[super loadView];

	self.title = NSLocalizedString(@"TERMINAL", @"Generic title displayed before the terminal sets a proper title.");;

	_textView = [[HBNTTerminalTextView alloc] initWithFrame:self.view.bounds];
	_textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_textView.showsVerticalScrollIndicator = NO;
	_textView.backgroundColor = _stringSupplier.colorMap.background;
	_textView.dataDetectorTypes = UIDataDetectorTypeLink;
	_textView.linkTextAttributes = @{
		NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
	};
	_textView.textContainerInset = UIEdgeInsetsZero;
	_textView.textContainer.lineFragmentPadding = 0;
	_textView.contentInset = UIEdgeInsetsMake(self.parentViewController.topLayoutGuide.length, 0, 0, 0);
	_textView.terminalInputDelegate = _terminalController;
	[self.view addSubview:_textView];

	self.toolbarItems = @[
		// TODO: this needs an icon
		[[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStylePlain target:self.parentViewController action:@selector(showSettings:)]
	];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	[self registerForKeyboardNotifications];
	self.showKeyboard = YES;

	[self updateScreenSize];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	[self unregisterForKeyboardNotifications];
	self.showKeyboard = NO;

	[self updateScreenSize];
}

- (void)viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
	[self updateScreenSize];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[self updateScreenSize];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	if (_launchFailed) {
		NSString *ok = NSLocalizedStringFromTableInBundle(@"OK", @"Localizable", [NSBundle bundleForClass:UIView.class], nil);

		UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"TERMINAL_LAUNCH_FAILED", @"Alert title displayed when a terminal could not be launched.") message:exception.reason preferredStyle:UIAlertControllerStyleAlert];
		[alertController addAction:[UIAlertAction actionWithTitle:ok style:UIAlertActionStyleCancel handler:nil]];
		[self.navigationController presentViewController:alertController animated:YES completion:nil];
	}
}

#pragma mark - Preferences

- (void)preferencesUpdated {
	_fontMetrics = [HBNTPreferences sharedInstance].fontMetrics;
	[self refresh];
}

#pragma mark - Calculations

- (int)screenWidth {
	return _buffer.screenSize.width;
}

- (int)screenHeight {
	return _buffer.screenSize.height;
}

#pragma mark - Screen

- (void)updateScreenSize {
	CGSize glyphSize = _fontMetrics.boundingBox;

	// Determine the screen size based on the font size
	CGFloat width = _textView.frame.size.width - _textView.textContainerInset.left - _textView.textContainerInset.right;
	CGFloat height = _textView.frame.size.height - _textView.textContainerInset.top - _textView.textContainerInset.bottom - _textView.contentInset.top - _textView.contentInset.bottom;

	ScreenSize size;
	size.width = floorf(width / glyphSize.width) - 2;
	size.height = floorf(height / glyphSize.height);

	// The font size should not be too small that it overflows the glyph buffers.
	// It is not worth the effort to fail gracefully (increasing the buffer size would
	// be better).
	NSParameterAssert(size.width < kMaxRowBufferSize);
	_buffer.screenSize = size;

	[_terminalController updateScreenSize];
}

- (void)refresh {
	// TODO: we shouldn't load all lines' attributed strings, just ones that changed

	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];

	for (int i = 0; i < _buffer.scrollbackLines + _buffer.numberOfRows; i++) {
		[attributedString appendAttributedString:[_stringSupplier attributedStringForLine:i]];
		[attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
	}

	[attributedString addAttribute:NSFontAttributeName value:_fontMetrics.font range:NSMakeRange(0, attributedString.string.length)];

	_textView.attributedText = attributedString;

	[self scrollToBottomWithInsets:_textView.scrollIndicatorInsets];
}

- (void)scrollToBottomWithInsets:(UIEdgeInsets)inset {
	CGPoint offset = _textView.contentOffset;
	offset.y = _buffer.scrollbackLines == 0 ? -inset.top : inset.bottom + _textView.contentSize.height - _textView.frame.size.height;

	_textView.contentOffset = offset;
}

- (void)readInputStream:(NSData *)data {
	// Simply forward the input stream down the VT100 processor. When it notices
	// changes to the screen, it should invoke our refresh delegate below.
	[_buffer readInputStream:data];
}

- (void)clearScreen {
	[_buffer clearScreen];
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
	_keyboardVisible = !_keyboardVisible;

	if (!_hasAppeared) {
		_hasAppeared = YES;
		_textView.showsVerticalScrollIndicator = YES;
	}

	self.navigationController.toolbarHidden = _keyboardVisible;

	CGRect keyboardFrame = ((NSValue *)notification.userInfo[UIKeyboardFrameEndUserInfoKey]).CGRectValue;

	UIEdgeInsets insets = _textView.contentInset;
	CGFloat toolbarHeight = self.navigationController.toolbar.frame.size.height;
	insets.bottom = _keyboardVisible ? keyboardFrame.size.height : toolbarHeight;

	[UIView animateWithDuration:((NSNumber *)notification.userInfo[UIKeyboardAnimationDurationUserInfoKey]).doubleValue animations:^{
		_textView.contentInset = insets;
		_textView.scrollIndicatorInsets = insets;
	}];
}

- (void)setShowKeyboard:(BOOL)showKeyboard {
	if (showKeyboard) {
		[_textView becomeFirstResponder];
	} else {
		[_textView resignFirstResponder];
	}
}

- (void)toggleKeyboard:(id)sender {
	self.showKeyboard = !_keyboardVisible;
}

@end
