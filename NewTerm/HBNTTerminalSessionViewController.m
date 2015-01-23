//
//  HBNTTerminalSessionViewController.m
//  NewTerm
//
//  Created by Adam D on 12/12/2014.
//  Copyright (c) 2014 HASHBANG Productions. All rights reserved.
//

#import "HBNTTerminalSessionViewController.h"
#import "HBNTTerminalController.h"
#import "HBNTTerminalKeyboard.h"
#import "HBNTServer.h"
#import "VT100.h"
#import "VT100StringSupplier.h"
#import "ColorMap.h"
#import "FontMetrics.h"

// TODO: a lot of this probably shouldn't be here...

@implementation HBNTTerminalSessionViewController {
	UITextView *_textView;
	NSMutableAttributedString *_attributedString;
	
	VT100 *_buffer;
	VT100StringSupplier *_stringSupplier;
	ColorMap *_colorMap;
	FontMetrics *_fontMetrics;
	HBNTTerminalController *_terminalController;
	HBNTTerminalKeyboard *_terminalKeyboard;
	
	BOOL _hasAppeared;
	BOOL _keyboardVisible;
}

- (instancetype)initWithServer:(HBNTServer *)server {
	self = [self init];
	
	if (self) {
		_server = server;
		
		_buffer = [[VT100 alloc] init];
		_buffer.refreshDelegate = self;
		
		_stringSupplier = [[VT100StringSupplier alloc] init];
		_stringSupplier.colorMap = [[ColorMap alloc] init];
		_stringSupplier.screenBuffer = _buffer;
		
		_terminalController = [[HBNTTerminalController alloc] init];
		
		_terminalKeyboard = [[HBNTTerminalKeyboard alloc] init];
		
		self.font = [UIFont fontWithName:@"SourceCodePro-Regular" size:13.f];
	}
	
	return self;
}

- (void)loadView {
	[super loadView];
	
	self.title = _server.name;
	
	[self.view addSubview:_terminalKeyboard];
	
	_textView = [[UITextView alloc] initWithFrame:self.view.bounds];
	_textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_textView.backgroundColor = [UIColor blackColor];
	_textView.showsVerticalScrollIndicator = NO;
	[self.view addSubview:_textView];
	
	@try {
		[_terminalController startSubProcess];
	} @catch (NSException *exception) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:L18N(@"Couldn’t start a terminal subprocess.") message:exception.reason delegate:nil cancelButtonTitle:L18N(@"OK") otherButtonTitles:nil];
		[alertView show];
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.showKeyboard = YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self updateScreenSize];
}

#pragma mark - Font

- (UIFont *)font {
	return _fontMetrics.font;
}

- (void)setFont:(UIFont *)font {
	_fontMetrics = [[FontMetrics alloc] initWithFont:font];
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
	CGSize frameSize = _textView.frame.size;
	CGFloat height = frameSize.height - _textView.contentInset.top - _textView.contentInset.bottom;
	
	ScreenSize size;
	size.width = floorf(frameSize.width / glyphSize.width);
	size.height = floorf(height / glyphSize.height);
	
	// The font size should not be too small that it overflows the glyph buffers.
	// It is not worth the effort to fail gracefully (increasing the buffer size would
	// be better).
	NSParameterAssert(size.width < kMaxRowBufferSize);
	_buffer.screenSize = size;
}

- (void)refresh {
	_textView.attributedText = (__bridge NSAttributedString *)[_stringSupplier newAttributedString:0];
	[self scrollToBottomWithInsets:_textView.scrollIndicatorInsets];
}

- (void)scrollToBottomWithInsets:(UIEdgeInsets)inset {
	CGPoint offset = _textView.contentOffset;
	offset.y = _buffer.scrollbackLines == 0 ? -inset.top : inset.bottom + _textView.contentSize.height - _textView.frame.size.height;
	
	_textView.contentOffset = offset;
}

- (void)readInputStream:(NSData *)data {
	// Simply forward the input stream down the VT100 processor.	When it notices
	// changes to the screen, it should invoke our refresh delegate below.
	[_buffer readInputStream:data];
}

- (void)clearScreen {
	[_buffer clearScreen];
}

#pragma mark - Selection

- (void)fillDataWithSelection:(NSMutableData *)data {
	NSMutableString *string = [[NSMutableString alloc] init];
	
	ScreenPosition startPos = _buffer.selectionStart;
	ScreenPosition endPos = _buffer.selectionEnd;
	
	if (startPos.x >= endPos.x && startPos.y >= endPos.y) {
		ScreenPosition tmp = startPos;
		startPos = endPos;
		endPos = tmp;
	}
	
	int currentY = startPos.y;
	int maxX = self.screenWidth;
	
	while (currentY <= endPos.y) {
		int startX = (currentY == startPos.y) ? startPos.x : 0;
		int endX = (currentY == endPos.y) ? endPos.x : maxX;
		int width = endX - startX;
		
		if (width > 0) {
			screen_char_t *row = [_buffer bufferForRow:currentY];
			screen_char_t *col = &row[startX];
			unichar buffer[kMaxRowBufferSize];
			
			for (int i = 0; i < width; ++i) {
				if (col->ch == '\0') {
					buffer[i] = ' ';
				} else {
					buffer[i] = col->ch;
				}
				
				col++;
			}
			
			[string appendString:[NSString stringWithCharacters:buffer length:width]];
		}
		
		currentY++;
	}
	
	[data appendData:[string dataUsingEncoding:NSUTF8StringEncoding]];
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
	_keyboardVisible = !_keyboardVisible;
	
	if (!_hasAppeared) {
		_hasAppeared = YES;
		_textView.showsVerticalScrollIndicator = YES;
	}
	
	self.navigationController.toolbarHidden = _keyboardVisible;
	
	UIEdgeInsets insets = _textView.contentInset;
	CGFloat toolbarHeight = self.navigationController.toolbar.frame.size.height;
	insets.bottom += _keyboardVisible ? -toolbarHeight : toolbarHeight;
	
	[UIView animateWithDuration:((NSNumber *)notification.userInfo[UIKeyboardAnimationDurationUserInfoKey]).doubleValue animations:^{
		_textView.contentInset = insets;
		_textView.scrollIndicatorInsets = insets;
	}];
}

- (void)setShowKeyboard:(BOOL)showKeyboard {
	if (showKeyboard) {
		[_terminalKeyboard becomeFirstResponder];
	} else {
		[_terminalKeyboard resignFirstResponder];
	}
}

- (void)toggleKeyboard:(id)sender {
	self.showKeyboard = !_keyboardVisible;
}

@end
