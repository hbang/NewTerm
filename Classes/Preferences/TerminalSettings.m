// TerminalSettings.m
// MobileTerminal

#import "TerminalSettings.h"
#import "VT100/ColorMap.h"

#ifndef kCFCoreFoundationVersionNumber_iOS_7_0
#define kCFCoreFoundationVersionNumber_iOS_7_0 847.20
#endif

#define IS_IPAD ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
#define IS_MODERN (kCFCoreFoundationVersionNumber > kCFCoreFoundationVersionNumber_iOS_7_0)

static NSString *const kDefaultFontName = @"SourceCodePro-Regular";
static NSString *const kFallbackFontName = @"CourierNewPSMT";
static NSString *const kFallbackFontNameModern = @"Menlo-Regular";
static CGFloat const kDefaultIPhoneFont = 12.f;
static CGFloat const kDefaultIPadFont = 16.f;

@implementation TerminalSettings

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
	
	NSString *fontName = [defaults objectForKey:@"fontName"] ?: kDefaultFontName;
	
	NSString *sizeKey = IS_IPAD ? @"fontSizePad" : @"fontSizePhone";
	CGFloat fontSize = 0;
	
	if ([defaults objectForKey:sizeKey]) {
		fontSize = ((NSNumber *)[defaults objectForKey:sizeKey]).floatValue;
	} else {
		fontSize = IS_IPAD ? kDefaultIPadFont : kDefaultIPhoneFont;
	}
	
	_font = [[UIFont fontWithName:fontName size:fontSize] retain];
	
	if (!_font) {
		_font = [[UIFont fontWithName:IS_MODERN ? kFallbackFontNameModern : kFallbackFontName size:fontSize] retain];
		
		if (!_font) {
			_font = [[UIFont systemFontOfSize:fontSize] retain];
		}
	}
	
	NSDictionary *themes = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Themes" ofType:@"plist"]];
	
	_colorMap = [defaults objectForKey:@"theme"] ? [[ColorMap alloc] initWithDictionary:themes[[defaults objectForKey:@"theme"]]] : [[ColorMap alloc] init];
	
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:TerminalSettingsDidChange object:nil]];
}

@end
