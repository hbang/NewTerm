//
//  HBNTHostTableViewCell.m
//  NewTerm
//
//  Created by Adam D on 21/07/2014.
//  Copyright (c) 2014 HASHBANG Productions. All rights reserved.
//

#import "HBNTHostTableViewCell.h"
#import "HBNTTextField.h"

static CGFloat const kHBNTHostTableViewCellWidth = 40.f;

@implementation HBNTHostTableViewCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithReuseIdentifier:reuseIdentifier];
	
	if (self) {
		self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
		self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
		self.textField.keyboardType = UIKeyboardTypeURL;
		
		_portTextField = [[HBNTTextField alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width - kHBNTHostTableViewCellWidth - kHBNTTableViewCellMargin, 0, kHBNTHostTableViewCellWidth, self.contentView.frame.size.height)];
		_portTextField.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
		_portTextField.delegate = self;
		_portTextField.textAlignment = NSTextAlignmentRight;
		_portTextField.keyboardType = UIKeyboardTypeNumberPad;
		_portTextField.adjustsFontSizeToFitWidth = YES;
		[self.contentView addSubview:_portTextField];
		
		CGRect textFieldFrame = self.textField.frame;
		textFieldFrame.size.width -= kHBNTHostTableViewCellWidth;
		self.textField.frame = textFieldFrame;
	}
	
	return self;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	if (textField == _portTextField) {
		return [textField.text stringByReplacingCharactersInRange:range withString:string].length < 6 && [string rangeOfCharacterFromSet:((NSCharacterSet *)[NSCharacterSet decimalDigitCharacterSet]).invertedSet].location == NSNotFound;
	}
	
	return YES;
}

@end
