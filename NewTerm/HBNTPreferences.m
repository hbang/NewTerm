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
		_preferences = [[HBPreferences alloc] initWithIdentifier:@"ws.hbang.newterm"];

		[_preferences registerObject:&_fontName default:@"Hack-Regular" forKey:@"FontName"];
		[_preferences registerFloat:&_fontSize default:13.f forKey:@"FontSize"];

		[self addObserver:self forKeyPath:@"_fontName" options:kNilOptions context:nil];
		[self addObserver:self forKeyPath:@"_fontSize" options:kNilOptions context:nil];

		[self _fontMetricsChanged];
	}

	return self;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"_fontName"] || [keyPath isEqualToString:@"_fontSize"]) {
		[self _fontMetricsChanged];
	}
}

#pragma mark - Create model objects from preferences

- (void)_fontMetricsChanged {
	UIFont *font = [UIFont fontWithName:_fontName size:_fontSize];

	if (!font) {
		HBLogWarn(@"font %@ size %f could not be initialised", _fontName, _fontSize);
		font = [UIFont fontWithName:@"Courier" size:13.f];
	}

	_fontMetrics = [[FontMetrics alloc] initWithFont:font];
}

@end
