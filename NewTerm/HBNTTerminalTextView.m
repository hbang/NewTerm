//
//  HBNTTerminalTextView.m
//  NewTerm
//
//  Created by Adam D on 26/01/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

#import "HBNTTerminalTextView.h"

@implementation HBNTTerminalTextView

- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer {
	self = [super initWithFrame:frame textContainer:textContainer];

	if (self) {
		[self _commonInit];
	}

	return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];

	if (self) {
		[self _commonInit];
	}

	return self;
}

- (void)_commonInit {
	self.backgroundColor = [UIColor blackColor];
	self.indicatorStyle = UIScrollViewIndicatorStyleWhite;
	self.showsHorizontalScrollIndicator = NO;
	self.dataDetectorTypes = UIDataDetectorTypeLink;
	self.editable = NO;

	if ([self respondsToSelector:@selector(setLinkTextAttributes:)]) {
		self.linkTextAttributes = @{
			NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
		};
	}

	if ([self respondsToSelector:@selector(textContainer)]) {
		self.textContainerInset = UIEdgeInsetsZero;
		self.textContainer.lineFragmentPadding = 0;
	}
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
