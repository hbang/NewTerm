// TerminalSettings.m
// MobileTerminal

#import "TerminalSettings.h"
#import "VT100/ColorMap.h"

#define IS_IPAD ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)

@implementation TerminalSettings

static NSString *const kDefaultFontName = @"SourceCodePro-Regular";
static CGFloat const kDefaultIPhoneFont = 12.f;
static CGFloat const kDefaultIPadFont = 16.f;

- (instancetype)init {
	self = [super init];
	
	if (self) {
		[self reload];
	}
	
	return self;
}

- (void)reload {
	[_arguments release];
	[_font release];
	[_colorMap release];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	_arguments = [defaults objectForKey:@"arguments"] ?: @"";
	
	NSString *fontName = [defaults objectForKey:@"fontName"];
	CGFloat fontSize = [defaults floatForKey:IS_IPAD ? @"fontSizePad" : @"fontSizePhone"];
	
	if (fontSize < 8.f) {
		fontSize = IS_IPAD ? kDefaultIPadFont : kDefaultIPhoneFont;
	}
	
	_font = [[UIFont fontWithName:fontName size:fontSize] retain];
	
	if (!_font) {
		_font = [[UIFont fontWithName:kDefaultFontName size:fontSize] retain];
		
		if (!_font) {
			_font = [[UIFont systemFontOfSize:fontSize] retain];
		}
	}
	
	NSDictionary *themes = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Themes" ofType:@"plist"]];
	
	_colorMap = [defaults objectForKey:@"theme"] ? [[ColorMap alloc] initWithDictionary:themes[[defaults objectForKey:@"colorMap"]]] : [[ColorMap alloc] init];
	
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:TerminalSettingsDidChange object:nil]];
}

@end
