// VT100RowStringSupplier.m
// MobileTerminal

#import "VT100StringSupplier.h"
#import "VT100ColorMap.h"
#import "VT100Types.h"
#import <NewTermCommon/NewTermCommon-Swift.h>

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

	for (int i = 0; i < width; ++i) {
		if (row[i].code == '\0') {
			unicharBuffer[i] = ' ';
		} else {
			unicharBuffer[i] = row[i].code;
		}
	}

	return [[NSString alloc] initWithCharacters:unicharBuffer length:width];
}

- (NSMutableAttributedString *)attributedStringForLine:(int)rowIndex {
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

	NSString *text = [self stringForLine:rowIndex];

	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	paragraphStyle.alignment = NSTextAlignmentLeft;
	paragraphStyle.baseWritingDirection = NSWritingDirectionLeftToRight;
	paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;

	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:@{
		NSFontAttributeName: _fontMetrics.regularFont,
		NSParagraphStyleAttributeName: paragraphStyle
	}];

	screen_char_t *row = [_screenBuffer bufferForRow:rowIndex];

	for (int i = 0; i < width; i++) {
		NSMutableDictionary *attributes = [self _charAttributes:row[i]];

		if (cursorPosition.x == i && cursorPosition.y == rowIndex) {
			attributes[NSForegroundColorAttributeName] = _colorMap.foregroundCursor;
			attributes[VT100AttributedStringBackgroundColor] = _colorMap.backgroundCursor;
		}

		[attributedString addAttributes:attributes range:NSMakeRange(i, 1)];
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
	Color *fgColor = [_colorMap colorAtIndex:c.foregroundColor];
	Color *bgColor = [_colorMap colorAtIndex:c.backgroundColor];

	// int underlineStyle = c.underline ? (NSUnderlineStyleSingle | NSUnderlineByWord) : 0;

	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	attributes[NSForegroundColorAttributeName] = fgColor;
	attributes[VT100AttributedStringBackgroundColor] = bgColor;
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
