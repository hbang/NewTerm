//
//  HBNTTerminalSessionViewController.m
//  NewTerm
//
//  Created by Adam D on 12/12/2014.
//  Copyright (c) 2014 HASHBANG Productions. All rights reserved.
//

#import "HBNTTerminalSessionViewController.h"
#import "HBNTServer.h"
#import "VT100.h"
#import "VT100StringSupplier.h"
#import "ColorMap.h"
#import "FontMetrics.h"

@implementation HBNTTerminalSessionViewController {
	UITextView *_textView;
	NSMutableAttributedString *_attributedString;
	
	VT100 *_buffer;
	VT100StringSupplier *_stringSupplier;
	ColorMap *_colorMap;
	FontMetrics *_fontMetrics;
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
		
		self.font = [UIFont fontWithName:@"SourceCodePro-Regular" size:13.f];
	}
	
	return self;
}

- (void)loadView {
	[super loadView];
	
	self.title = _server.name;
	
	_textView = [[UITextView alloc] initWithFrame:self.view.bounds];
	_textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_textView.backgroundColor = [UIColor blackColor];
	[self.view addSubview:_textView];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[_textView becomeFirstResponder];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self updateScreenSize];
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
	[self scrollToBottomWithInsets:_textView.scrollIndicatorInsets];
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

@end
