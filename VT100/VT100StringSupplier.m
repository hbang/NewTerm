// VT100RowStringSupplier.m
// MobileTerminal

#import "VT100StringSupplier.h"
#import "VT100ColorMap.h"
#import "VT100Types.h"

@implementation VT100StringSupplier

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

	if (rowIndex != self.rowCount) {
		unicharBuffer[width] = '\n';
		width += 1;
	}

	return [[NSString alloc] initWithBytes:unicharBuffer length:width encoding:NSUTF8StringEncoding];
}

- (NSAttributedString *)attributedString {
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

	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:allLines];
	NSUInteger startOffset = 0;

	for (int i = 0; i < self.rowCount; i++) {
		// Update the string with background/foreground color attributes. This loop compares the colors
		// of characters and sets the attribute when it runs into a character of a different color. It
		// runs one extra time to set the attribute for the run of characters at the end of the line.
		NSUInteger lastColorIndex = NSUIntegerMax;
		UIColor *lastColor = nil;
		screen_char_t *row = [_screenBuffer bufferForRow:i];

		// TODO(aporter): This looks a lot more complicated than it needs to be. Try
		// this again with fewer lines of code.
		for (int j = 0; j <= width; ++j) {
			BOOL eol = (j == width); // reached end of line
			UIColor *color = nil;

			if (!eol) {
				color = [_colorMap colorAtIndex:row[j].backgroundColor];

				if (cursorPosition.x == j && cursorPosition.y == i) {
					color = _colorMap.backgroundCursor;
				}
			}

			if (eol || ![color isEqual:lastColor]) {
				if (lastColorIndex != NSUIntegerMax) {
					int length = j - lastColorIndex;
					[attributedString addAttribute:NSBackgroundColorAttributeName value:lastColor range:NSMakeRange(startOffset + lastColorIndex, length)];
				}

				if (!eol) {
					lastColorIndex = j;
					lastColor = color;
				}
			}
		}

		// Same thing again for foreground color
		lastColorIndex = -1;
		lastColor = nil;

		for (int j = 0; j <= width; ++j) {
			BOOL eol = (j == width); // reached end of line
			UIColor *color = nil;

			if (!eol) {
				color = [_colorMap colorAtIndex:row[j].foregroundColor];

				if (cursorPosition.x == j && cursorPosition.y == i) {
					color = _colorMap.foregroundCursor;
				}
			}

			if (eol || ![color isEqual:lastColor]) {
				if (lastColorIndex != -1) {
					int length = j - lastColorIndex;
					[attributedString addAttribute:NSForegroundColorAttributeName value:lastColor range:NSMakeRange(startOffset + lastColorIndex, length)];
				}

				if (!eol) {
					lastColorIndex = j;
					lastColor = color;
				}
			}
		}

		startOffset += width;
	}

	return attributedString;
}

@end
