// TerminalKeyboard.m
// MobileTerminal

#import "TerminalKeyboard.h"
#import "TerminalKeyInput.h"

@implementation TerminalKeyboard

@synthesize inputDelegate;

- (id)init {
	self = [super init];
	if (self != nil) {
		[self setOpaque:YES];
		_inputTextField = [[TerminalKeyInput alloc] initWithKeyboard:self];
		[self addSubview:_inputTextField];
	}
	return self;
}

- (void)drawRect:(CGRect)rect {
	// Nothing to see here
}

- (BOOL)becomeFirstResponder {
	// XXX
	return [_inputTextField becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
	return [_inputTextField resignFirstResponder];
}
	
- (void)dealloc {
	[_inputTextField release];
	[super dealloc];
}

@end
