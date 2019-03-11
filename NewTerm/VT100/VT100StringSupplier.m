// VT100RowStringSupplier.m
// MobileTerminal

#import "VT100StringSupplier.h"
#import "VT100ColorMap.h"
#import "VT100Types.h"
#import "FontMetrics.h"
#import <version.h>

@implementation VT100StringSupplier {
	NSMutableSet <NSValue *> *_lastLinkRanges;
	NSDataDetector *_linkDataDetector;
}

- (int)rowCount {
	return _screenBuffer.numberOfRows;
}

- (int)columnCount {
	return _screenBuffer.screenSize.width;
}

- (NSString *)stringForLine:(int)rowIndex {
	// Buffer of characters to draw on the screen, holds up to one row
	unichar unicharBuffer[kMaxRowBufferSize];

	// TODO(aporter): Make the screen object itself return an attributed string?
	int width = self.columnCount;
	screen_char_t *row = [_screenBuffer bufferForRow:rowIndex];

	for (int j = 0; j < width; ++j) {
		if (row[j].code == '\0') {
			unicharBuffer[j] = ' ';
		} else {
			unicharBuffer[j] = row[j].code;
		}
	}

	// UITextView won’t render a massive line of spaces (e.g. an empty nano screen), so add a newline
	// if the line ends with a space
	if (rowIndex != self.rowCount - 1 && unicharBuffer[width - 1] == ' ') {
		unicharBuffer[width - 1] = '\n';
	}

	return [[NSString alloc] initWithCharacters:unicharBuffer length:width];
}

- (NSMutableAttributedString *)attributedString {
	NSParameterAssert(_fontMetrics);
	NSParameterAssert(_fontMetrics.regularFont);
	NSParameterAssert(_fontMetrics.boldFont);
	NSParameterAssert(_screenBuffer);
	NSParameterAssert(_colorMap);

	int width = self.columnCount;
	ScreenPosition cursorPosition = _screenBuffer.cursorPosition;

	// The cursor is initially relative to the screen, not the position in the
	// scrollback buffer.
	if (_screenBuffer.numberOfRows > _screenBuffer.screenSize.height) {
		cursorPosition.y += _screenBuffer.numberOfRows - _screenBuffer.screenSize.height;
	}

	NSMutableString *allLines = [NSMutableString string];

	for (int i = 0; i < self.rowCount; i++) {
		[allLines appendString:[self stringForLine:i]];
	}

	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	paragraphStyle.alignment = NSTextAlignmentLeft;
	paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;

	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:allLines attributes:@{
		NSFontAttributeName: _fontMetrics.regularFont,
		NSParagraphStyleAttributeName: paragraphStyle
	}];

	for (int i = 0; i < self.rowCount; i++) {
		screen_char_t *row = [_screenBuffer bufferForRow:i];

		for (int j = 0; j <= width; j++) {
			int location = (i * width) + j;
			if (location + 1 > allLines.length) {
				continue;
			}

			NSMutableDictionary *attributes = [self _charAttributes:row[j]];

			if (cursorPosition.x == j && cursorPosition.y == i) {
				attributes[NSForegroundColorAttributeName] = _colorMap.foregroundCursor;
				attributes[NSBackgroundColorAttributeName] = _colorMap.backgroundCursor;
			}

			[attributedString addAttributes:attributes range:NSMakeRange(location, 1)];
		}
	}

	// create links in all the locations we found last time we scanned for links
	for (NSValue *value in _lastLinkRanges) {
		NSRange range = value.rangeValue;

		if (range.location + range.length <= attributedString.string.length) {
			NSString *urlString = [attributedString.string substringWithRange:range];
			NSURL *url = [NSURL URLWithString:urlString];

			// if NSURL thinks this is a valid url, it’s good enough for us
			if (url) {
				[attributedString addAttribute:NSLinkAttributeName value:url range:range];
			}
		}
	}

	return attributedString;
}

- (NSMutableDictionary *)_charAttributes:(screen_char_t)c {
	UIColor *fgColor = [_colorMap colorAtIndex:c.foregroundColor];
	UIColor *bgColor = [_colorMap colorAtIndex:c.backgroundColor];

	// int underlineStyle = c.underline ? (NSUnderlineStyleSingle | NSUnderlineByWord) : 0;

	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	attributes[NSForegroundColorAttributeName] = fgColor;
	attributes[NSBackgroundColorAttributeName] = bgColor;
	// attributes[NSUnderlineStyleAttributeName] = @(underlineStyle);
	return attributes;
}

- (void)detectLinksForAttributedString:(NSMutableAttributedString *)attributedString {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_lastLinkRanges = [NSMutableSet set];

		// not exactly sure why a data detector would fail to init…
		NSError *error = nil;
		_linkDataDetector = [[NSDataDetector alloc] initWithTypes:NSTextCheckingTypeLink error:&error];
		NSAssert(!error, @"%@", error.description);
	});

	NSMutableSet *addedLinkRanges = [NSMutableSet set];
	NSMutableSet *removedLinkRanges = [NSMutableSet set];

	[_linkDataDetector enumerateMatchesInString:attributedString.string options:kNilOptions range:NSMakeRange(0, attributedString.string.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
		[addedLinkRanges addObject:[NSValue valueWithRange:result.range]];
	}];

	for (NSValue *value in _lastLinkRanges) {
		NSRange range = value.rangeValue;

		// if it starts after the end of the string, it’s already been removed. don’t worry about it
		if (range.location >= attributedString.string.length) {
			continue;
		}

		// if it ends further than the end of the string, subtract the difference from the length
		if (range.location + range.length >= attributedString.string.length) {
			range.length -= (range.location + range.length) - attributedString.string.length;
		}

		NSURL *url = [NSURL URLWithString:[attributedString.string substringWithRange:range]];

		// if this link is now invalid, or wasn’t found in this latest refresh, remove it
		if (!url || ![addedLinkRanges containsObject:value]) {
			[addedLinkRanges removeObject:value];
			[removedLinkRanges addObject:value];

			[attributedString removeAttribute:NSLinkAttributeName range:value.rangeValue];
		}
	}

	for (NSValue *value in addedLinkRanges) {
		// if this link is new, create its attributes
		if (![_lastLinkRanges containsObject:value]) {
			NSRange range = value.rangeValue;
			NSURL *url = [NSURL URLWithString:[attributedString.string substringWithRange:range]];
			[attributedString addAttribute:NSLinkAttributeName value:url range:range];
		}
	}

	// remember these link ranges for the next refresh
	_lastLinkRanges = addedLinkRanges;
}

@end
