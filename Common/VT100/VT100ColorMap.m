// ColorMap.m
// MobileTerminal

#import "VT100ColorMap.h"
#import "VT100Terminal.h"
#import "Extensions/UIColor+HBAdditions.h"

@interface VT100ColorMap () {
	Color *_table[COLOR_MAP_MAX_COLORS];
}

@end

@implementation VT100ColorMap

- (instancetype)init {
	self = [super init];

	if (self) {
		_background       = [Color colorWithWhite:0.f alpha:1.f];
		_foreground	      = [Color colorWithWhite:0.95f alpha:1.f];
		_foregroundBold   = [Color colorWithWhite:1.f alpha:1.f];
		_foregroundCursor = [Color colorWithWhite:0.95f alpha:1.f];
		_backgroundCursor = [Color colorWithWhite:0.4f alpha:1.f];
		_isDark = YES;

		// System 7.5 colors, why not?
		_table[kiTermScreenCharAnsiColorBlack]         = [Color colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.f];
		_table[kiTermScreenCharAnsiColorRed]           = [Color colorWithRed:0.6f green:0.0f blue:0.0f alpha:1.f];
		_table[kiTermScreenCharAnsiColorGreen]         = [Color colorWithRed:0.0f green:0.6f blue:0.0f alpha:1.f];
		_table[kiTermScreenCharAnsiColorYellow]        = [Color colorWithRed:0.6f green:0.4f blue:0.0f alpha:1.f];
		_table[kiTermScreenCharAnsiColorBlue]          = [Color colorWithRed:0.0f green:0.0f blue:0.6f alpha:1.f];
		_table[kiTermScreenCharAnsiColorMagenta]       = [Color colorWithRed:0.6f green:0.0f blue:0.6f alpha:1.f];
		_table[kiTermScreenCharAnsiColorCyan]          = [Color colorWithRed:0.0f green:0.6f blue:0.6f alpha:1.f];
		_table[kiTermScreenCharAnsiColorWhite]         = [Color colorWithRed:0.6f green:0.6f blue:0.6f alpha:1.f];
		_table[kiTermScreenCharAnsiColorBrightBlack]   = [Color colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.f];
		_table[kiTermScreenCharAnsiColorBrightRed]     = [Color colorWithRed:1.0f green:0.0f blue:0.0f alpha:1.f];
		_table[kiTermScreenCharAnsiColorBrightGreen]   = [Color colorWithRed:0.0f green:1.0f blue:0.0f alpha:1.f];
		_table[kiTermScreenCharAnsiColorBrightYellow]  = [Color colorWithRed:1.0f green:1.0f blue:0.0f alpha:1.f];
		_table[kiTermScreenCharAnsiColorBrightBlue]    = [Color colorWithRed:0.0f green:0.0f blue:1.0f alpha:1.f];
		_table[kiTermScreenCharAnsiColorBrightMagenta] = [Color colorWithRed:1.0f green:0.0f blue:1.0f alpha:1.f];
		_table[kiTermScreenCharAnsiColorBrightCyan]    = [Color colorWithRed:0.0f green:1.0f blue:1.0f alpha:1.f];
		_table[kiTermScreenCharAnsiColorBrightWhite]   = [Color colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.f];
	}

	return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
	self = [self init];

	if (self) {
		if (dictionary[@"Background"]) {
			_background = [Color colorWithPropertyListValue:dictionary[@"Background"]];
		}

		if (dictionary[@"Text"]) {
			_foreground = [Color colorWithPropertyListValue:dictionary[@"Text"]];
		}

		if (dictionary[@"BoldText"]) {
			_foregroundBold = [Color colorWithPropertyListValue:dictionary[@"BoldText"]];
		}

		if (dictionary[@"Cursor"]) {
			_foregroundCursor = [Color colorWithPropertyListValue:dictionary[@"Cursor"]];
			_backgroundCursor = [Color colorWithPropertyListValue:dictionary[@"Cursor"]];
		}

		if (dictionary[@"IsDark"]) {
			_isDark = ((NSNumber *)dictionary[@"IsDark"]).boolValue;
		}

		if (dictionary[@"ColorTable"] && [dictionary[@"ColorTable"] isKindOfClass:NSArray.class] && ((NSDictionary *)dictionary[@"ColorTable"]).count == COLOR_MAP_MAX_COLORS) {
			NSArray *colors = dictionary[@"ColorTable"];
			for (int i = 0; i < colors.count; i++) {
				_table[i] = [Color colorWithPropertyListValue:colors[i]];
			}
		}
	}

	return self;
}

- (Color *)colorAtIndex:(unsigned int)index {
	// TODO(allen): The logic here is pretty ad hoc and could use some some helpful comments
	// describing whats its doing. It seems to work?
	if (index == -1) {
		return isBackground ? nil : _background;
	} else if (index & COLOR_CODE_MASK) {
		switch (index) {
			case CURSOR_TEXT:
				return _foregroundCursor;
			case CURSOR_BG:
				return _backgroundCursor;
			case BG_COLOR_CODE:
				return isBackground ? nil : _background;
			default:
				if (index & BOLD_MASK) {
					if (index - BOLD_MASK == BG_COLOR_CODE) {
						return isBackground ? nil : _background;
					} else {
						return _foregroundBold;
					}
				} else {
					return _foreground;
				}
		}
	} else {
		index &= 0xff;
		if (index < 16) {
			// predefined color
			return _table[index];
		} else if (index < 232) {
			// 256-color
			index -= 16;
			CGFloat components[] = {
				(index / 36) ? ((index / 36) * 40 + 55) / 255.0 : 0.0,
				(index % 36) / 6 ? (((index % 36) / 6) * 40 + 55) / 255.0 : 0.0,
				(index % 6) ? ((index % 6) * 40 + 55) / 255.0 : 0.0,
				1.0
			};
			return [Color colorWithRed:components[0] green:components[1] blue:components[2] alpha:1.0f];
		} else if (index < 256) {
			// grayscale
			index -= 232;
			CGFloat gray = (index * 10 + 8) / 255.0;
			return [Color colorWithWhite:gray alpha:1.0f];
		} else {
			return _foreground;
		}
	}
}

@end
