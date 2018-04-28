#import "HBNTTerminalSampleView.h"
#import <VT100/VT100.h>
#import <VT100/VT100ColorMap.h>
#import <VT100/VT100StringSupplier.h>

// TODO: this somehow needs to be fixed. move it into the main app?

@implementation HBNTTerminalSampleView {
	// HBNTTerminalTextView *_textView;
	VT100 *_buffer;
	VT100StringSupplier *_stringSupplier;
}

// - (instancetype)initWithFrame:(CGRect)frame {
// 	self = [super initWithFrame:frame];

// 	if (self) {
// 		_buffer = [[%c(VT100) alloc] init];

// 		_stringSupplier = [[%c(VT100StringSupplier) alloc] init];
// 		_stringSupplier.colorMap = [[%c(VT100ColorMap) alloc] init];
// 		_stringSupplier.screenBuffer = _buffer;

// 		_textView = [[%c(HBNTTerminalTextView) alloc] initWithFrame:self.bounds];
// 		_textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
// 		_textView.editable = NO;
// 		_textView.selectable = NO;
// 		[self addSubview:_textView];

// 		NSData *colorTest = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"colortest" withExtension:@"txt"]];
// 		[_buffer readInputStream:colorTest];

// 		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesUpdated) name:HBPreferencesDidChangeNotification object:nil];
// 		[self preferencesUpdated];
// 	}

// 	return self;
// }

// - (void)preferencesUpdated {
// 	HBNTPreferences *preferences = [%c(HBNTPreferences) sharedInstance];

// 	_stringSupplier.colorMap = preferences.colorMap;
// 	_stringSupplier.fontMetrics = preferences.fontMetrics;
// 	_textView.backgroundColor = _stringSupplier.colorMap.background;
// 	_textView.attributedText = _stringSupplier.attributedString;
// }

@end
