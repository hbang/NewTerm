//
//  HBNTPreferences.m
//  NewTerm
//
//  Created by Adam Demasi on 21/11/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

#import "HBNTPreferences.h"
#import "FontMetrics.h"
#import "VT100ColorMap.h"

@implementation HBNTPreferences {
	HBPreferences *_preferences;

	NSDictionary *_fontsPlist;
	NSDictionary *_themesPlist;

	NSString *_fontName;
	CGFloat _fontSize;
	NSString *_themeName;
}

+ (instancetype)sharedInstance {
	static HBNTPreferences *sharedInstance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self alloc] init];
	});

	return sharedInstance;
}

- (instancetype)init {
	self = [super init];

	if (self) {
		_preferences = [[HBPreferences alloc] initWithIdentifier:@"ws.hbang.Terminal"];

		[_preferences registerObject:&_fontName default:@"Fira Code" forKey:@"fontName"];
		[_preferences registerFloat:&_fontSize default:13.f forKey:IS_IPAD ? @"fontSizePad" : @"fontSizePhone"];
		[_preferences registerObject:&_themeName default:@"kirb" forKey:@"theme"];

		_fontsPlist = [NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Fonts" withExtension:@"plist"]];
		_themesPlist = [NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Themes" withExtension:@"plist"]];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesUpdated) name:HBPreferencesDidChangeNotification object:nil];
		[self preferencesUpdated];
	}

	return self;
}

#pragma mark - Callbacks

- (void)preferencesUpdated {
	[self _fontMetricsChanged];
	[self _colorMapChanged];
}

#pragma mark - Create model objects from preferences

- (void)_fontMetricsChanged {
	NSDictionary *family = _fontsPlist[_fontName];
	UIFont *regularFont, *boldFont;

	if (family) {
		// if we have the font name as a known family, use its regular and bold names
		regularFont = [UIFont fontWithName:family[@"Regular"] size:_fontSize];
		boldFont = [UIFont fontWithName:family[@"Bold"] size:_fontSize];
	} else {
		// fallback for older style: raw font name stored in preferences. bold not supported
		regularFont = [UIFont fontWithName:_fontName size:_fontSize];
		boldFont = [UIFont fontWithName:_fontName size:_fontSize];
	}

	if (!regularFont || !boldFont) {
		HBLogWarn(@"font %@ size %f could not be initialised", _fontName, _fontSize);
		regularFont = [UIFont fontWithName:@"Courier" size:13.f];
		boldFont = [UIFont fontWithName:@"Courier-Bold" size:13.f];
	}

	_fontMetrics = [[FontMetrics alloc] initWithFont:regularFont boldFont:boldFont];
}

- (void)_colorMapChanged {
	// if the theme doesn’t exist… how did we get here? force it to the default, which will call this
	// method again
	if (!_themesPlist[_themeName]) {
		_preferences[@"theme"] = @"kirb";
		return;
	}

	_colorMap = [[VT100ColorMap alloc] initWithDictionary:_themesPlist[_themeName]];
}

@end
