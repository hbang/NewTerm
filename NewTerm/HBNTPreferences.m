//
//  HBNTPreferences.m
//  NewTerm
//
//  Created by Adam Demasi on 21/11/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

#import "HBNTPreferences.h"
#import "FontMetrics.h"

@implementation HBNTPreferences {
	HBPreferences *_preferences;

	NSDictionary *_fontFamilies;

	NSString *_fontName;
	CGFloat _fontSize;
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

		_fontFamilies = [NSDictionary dictionaryWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"Fonts" withExtension:@"plist"]];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferencesUpdated) name:HBPreferencesDidChangeNotification object:nil];
		[self preferencesUpdated];
	}

	return self;
}

#pragma mark - Callbacks

- (void)preferencesUpdated {
	[self _fontMetricsChanged];
}

#pragma mark - Create model objects from preferences

- (void)_fontMetricsChanged {
	NSDictionary *family = _fontFamilies[_fontName];
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

@end
