//
//  HBNTTerminalTextView.m
//  NewTerm
//
//  Created by Adam D on 26/01/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

#import "HBNTTerminalTextView.h"
#import "HBNTKeyboardButton.h"
#import "HBNTKeyboardToolbar.h"

#ifndef __IPHONE_11_0
#define UITextSmartQuotesType NSInteger
#define UITextSmartDashesType NSInteger
#define UITextSmartInsertDeleteType NSInteger
#define UITextSmartQuotesTypeNo 1
#define UITextSmartDashesTypeNo 1
#define UITextSmartInsertDeleteTypeNo 1

@interface UITextView ()

@property (nonatomic) UITextSmartQuotesType smartQuotesType NS_AVAILABLE_IOS(11_0); // default is UITextSmartQuotesTypeDefault
@property (nonatomic) UITextSmartDashesType smartDashesType NS_AVAILABLE_IOS(11_0); // default is UITextSmartDashesTypeDefault
@property (nonatomic) UITextSmartInsertDeleteType smartInsertDeleteType NS_AVAILABLE_IOS(11_0); // default is UITextSmartInsertDeleteTypeDefault

@end
#endif

@implementation HBNTTerminalTextView {
	HBNTKeyboardToolbar *_toolbar;
	HBNTKeyboardButton *_ctrlKey, *_metaKey;
	BOOL _ctrlDown, _metaDown;

	NSData *_backspaceData, *_tabKeyData, *_upKeyData, *_downKeyData, *_leftKeyData, *_rightKeyData;
}

- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer {
	self = [super initWithFrame:frame textContainer:textContainer];

	if (self) {
		self.backgroundColor = [UIColor blackColor];
		self.indicatorStyle = UIScrollViewIndicatorStyleWhite;
		self.showsHorizontalScrollIndicator = NO;
		self.dataDetectorTypes = UIDataDetectorTypeNone;
		self.editable = NO;
		self.linkTextAttributes = @{
			NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
		};
		self.textContainerInset = UIEdgeInsetsZero;
		self.textContainer.lineFragmentPadding = 0;
	}

	return self;
}

#pragma mark - UIResponder

- (BOOL)becomeFirstResponder {
	// we aren’t meant to ever become first responder. that’s the job of HBNTTerminalKeyInput
	return NO;
}

#pragma mark - UITextInput

- (CGRect)caretRectForPosition:(UITextPosition *)position {
	// TODO: should we take advantage of this?
	return CGRectZero;
}

@end
