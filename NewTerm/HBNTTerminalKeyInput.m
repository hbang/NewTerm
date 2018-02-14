#import "HBNTTerminalKeyInput.h"
#import "HBNTKeyboardButton.h"
#import "HBNTKeyboardToolbar.h"

@implementation HBNTTerminalKeyInput {
	HBNTKeyboardToolbar *_toolbar;
	HBNTKeyboardButton *_ctrlKey, *_metaKey;
	BOOL _ctrlDown, _metaDown;

	NSData *_backspaceData, *_tabKeyData, *_upKeyData, *_downKeyData, *_leftKeyData, *_rightKeyData;
}

- (instancetype)init {
	self = [super init];

	if (self) {
		self.autocapitalizationType = UITextAutocapitalizationTypeNone;
		self.autocorrectionType = UITextAutocorrectionTypeNo;
		self.spellCheckingType = UITextSpellCheckingTypeNo;

		if (@available(iOS 11.0, *)) {
			self.smartQuotesType = UITextSmartQuotesTypeNo;
			self.smartDashesType = UITextSmartDashesTypeNo;
			self.smartInsertDeleteType = UITextSmartInsertDeleteTypeNo;
		}

		// TODO: this should be themable
		self.keyboardAppearance = UIKeyboardAppearanceDark;

		// TODO: this is kinda ugly and causes duped code for these buttons
		if (IS_IPAD && [self respondsToSelector:@selector(inputAssistantItem)]) {
			_ctrlKey = [HBNTKeyboardButton buttonWithTitle:@"Ctrl" target:self action:@selector(ctrlKeyPressed:)];
			_metaKey = [HBNTKeyboardButton buttonWithTitle:@"Esc" target:self action:@selector(metaKeyPressed:)];
			
			self.inputAssistantItem.allowsHidingShortcuts = NO;
			self.inputAssistantItem.leadingBarButtonGroups = [self.inputAssistantItem.leadingBarButtonGroups arrayByAddingObject:
				[[UIBarButtonItemGroup alloc] initWithBarButtonItems:@[
					[[UIBarButtonItem alloc] initWithCustomView:_ctrlKey],
					[[UIBarButtonItem alloc] initWithCustomView:_metaKey],
					[[UIBarButtonItem alloc] initWithCustomView:[HBNTKeyboardButton buttonWithTitle:@"Tab" target:self action:@selector(tabKeyPressed:)]]
				] representativeItem:nil]];
			self.inputAssistantItem.trailingBarButtonGroups = [self.inputAssistantItem.trailingBarButtonGroups arrayByAddingObject:
				[[UIBarButtonItemGroup alloc] initWithBarButtonItems:@[
					[[UIBarButtonItem alloc] initWithCustomView:[HBNTKeyboardButton buttonWithTitle:@"▲" target:self action:@selector(upKeyPressed:)]],
					[[UIBarButtonItem alloc] initWithCustomView:[HBNTKeyboardButton buttonWithTitle:@"▼" target:self action:@selector(downKeyPressed:)]],
					[[UIBarButtonItem alloc] initWithCustomView:[HBNTKeyboardButton buttonWithTitle:@"◀" target:self action:@selector(leftKeyPressed:)]],
					[[UIBarButtonItem alloc] initWithCustomView:[HBNTKeyboardButton buttonWithTitle:@"▶" target:self action:@selector(rightKeyPressed:)]]
				] representativeItem:nil]];
		} else {
			_toolbar = [[HBNTKeyboardToolbar alloc] init];
			_toolbar.translatesAutoresizingMaskIntoConstraints = NO;
			[_toolbar.ctrlKey addTarget:self action:@selector(ctrlKeyPressed:) forControlEvents:UIControlEventTouchUpInside];
			[_toolbar.metaKey addTarget:self action:@selector(metaKeyPressed:) forControlEvents:UIControlEventTouchUpInside];
			[_toolbar.tabKey addTarget:self action:@selector(tabKeyPressed:) forControlEvents:UIControlEventTouchUpInside];
			[_toolbar.upKey addTarget:self action:@selector(upKeyPressed:) forControlEvents:UIControlEventTouchUpInside];
			[_toolbar.downKey addTarget:self action:@selector(downKeyPressed:) forControlEvents:UIControlEventTouchUpInside];
			[_toolbar.leftKey addTarget:self action:@selector(leftKeyPressed:) forControlEvents:UIControlEventTouchUpInside];
			[_toolbar.rightKey addTarget:self action:@selector(rightKeyPressed:) forControlEvents:UIControlEventTouchUpInside];
			
			_ctrlKey = _toolbar.ctrlKey;
			_metaKey = _toolbar.metaKey;

			_backspaceData = [NSData dataWithBytes:"\x7F" length:1];
			_tabKeyData = [NSData dataWithBytes:"\t" length:1];
			_upKeyData = [NSData dataWithBytes:"\e[A" length:3];
			_downKeyData = [NSData dataWithBytes:"\e[B" length:3];
			_leftKeyData = [NSData dataWithBytes:"\e[D" length:3];
			_rightKeyData = [NSData dataWithBytes:"\e[C" length:3];
		}
	}

	return self;
}

- (UIView *)inputAccessoryView {
	return _toolbar;
}

#pragma mark - Callbacks

- (void)ctrlKeyPressed:(UIButton *)button {
	_ctrlDown = !_ctrlDown;
	button.selected = _ctrlDown;
}

- (void)metaKeyPressed:(UIButton *)button {
	_metaDown = !_metaDown;
	button.selected = _metaDown;
}

- (void)tabKeyPressed:(UIButton *)button {
	[_terminalInputDelegate receiveKeyboardInput:_tabKeyData];
}

- (void)upKeyPressed:(UIButton *)button {
	[_terminalInputDelegate receiveKeyboardInput:_upKeyData];
}

- (void)downKeyPressed:(UIButton *)button {
	[_terminalInputDelegate receiveKeyboardInput:_downKeyData];
}

- (void)leftKeyPressed:(UIButton *)button {
	[_terminalInputDelegate receiveKeyboardInput:_leftKeyData];
}

- (void)rightKeyPressed:(UIButton *)button {
	[_terminalInputDelegate receiveKeyboardInput:_rightKeyData];
}

#pragma mark - UITextInput

- (BOOL)hasText {
	return YES;
}

- (void)insertText:(NSString *)input {
	// mobile terminal used to use the bullet key • as a ctrl equivalent. continue to support that
	// TODO: is this just a nuisance? what if you actually want to type a bullet?
	if ([input characterAtIndex:0] == 0x2022) {
		_ctrlDown = YES;
		_ctrlKey.selected = YES;
		return;
	}
	
	NSMutableData *data = [NSMutableData data];

	unichar characters[input.length];
	[input getCharacters:characters range:NSMakeRange(0, input.length)];

	for (int i = 0; i < input.length; i++) {
		unichar character = characters[i];

		if (_ctrlDown) {
			// translate capital to lowercase
			if (character >= 'A' && character <= 'Z') {
				character += 'a' - 'A';
			}
			
			// convert to the matching control character
			if (character >= 'a' && character <= 'z') {
				character -= 'a' - 1;
			}
		} else if (_metaDown) {
			// prepend the escape character
			[data appendBytes:"\e" length:1];
		}
		
		if (character == 0x0a) {
			// Convert newline to a carraige return
			character = 0x0d;
		}

		// Re-encode as UTF8
		[data appendBytes:&character length:1];
	}

	[_terminalInputDelegate receiveKeyboardInput:data];
	
	if (_ctrlDown) {
		_ctrlDown = NO;
		_ctrlKey.selected = NO;
	}
	
	if (_metaDown) {
		_metaDown = NO;
		_metaKey.selected = NO;
	}
}

- (void)deleteBackward {
	[_terminalInputDelegate receiveKeyboardInput:_backspaceData];
}

#pragma mark - UIResponder

- (BOOL)becomeFirstResponder {
	[super becomeFirstResponder];
	return YES;
}

- (BOOL)canBecomeFirstResponder {
	return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	if (action == @selector(paste:)) {
		// Only paste if the board contains plain text
		return [[UIPasteboard generalPasteboard] containsPasteboardTypes:UIPasteboardTypeListString];
	} else if (action == @selector(cut:)) {
		// ensure cut is never allowed
		return NO;
	} else if (action == @selector(copy) || action == @selector(select:) || action == @selector(selectAll:)) {
		// allow copy, select, select all based on what the text view feels like doing
		return [_textView canPerformAction:action withSender:sender];
	}
	
	// consult the super implementation’s opinion
	return [super canPerformAction:action withSender:sender];
}

- (void)copy:(id)sender {
	// forward the operation to the text view
	[_textView copy:sender];
}

- (void)select:(id)sender {
	[_textView select:sender];
}

- (void)selectAll:(id)sender {
	[_textView selectAll:sender];
}

- (void)paste:(id)sender {
	UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];

	if (![pasteboard containsPasteboardTypes:UIPasteboardTypeListString]) {
		return;
	}

	[_terminalInputDelegate receiveKeyboardInput:[pasteboard.string dataUsingEncoding:NSUTF8StringEncoding]];
}

@end
