/*
 **  NSStringIterm.m
 **
 **  Copyright (c) 2002, 2003
 **
 **  Author: Fabian
 **      Initial code by Kiichi Kusama
 **
 **  Project: iTerm
 **
 **  Description: Implements NSString extensions.
 **
 **  This program is free software; you can redistribute it and/or modify
 **  it under the terms of the GNU General Public License as published by
 **  the Free Software Foundation; either version 2 of the License, or
 **  (at your option) any later version.
 **
 **  This program is distributed in the hope that it will be useful,
 **  but WITHOUT ANY WARRANTY; without even the implied warranty of
 **  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 **  GNU General Public License for more details.
 **
 **  You should have received a copy of the GNU General Public License
 **  along with this program; if not, write to the Free Software
 **  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#import "NSStringITerm.h"
#import "NSCharacterSet+iTerm.h"

@implementation NSString (iTerm)

+ (BOOL)isDoubleWidthCharacter:(int)unicode
        ambiguousIsDoubleWidth:(BOOL)ambiguousIsDoubleWidth
                unicodeVersion:(NSInteger)version {
	if (unicode <= 0xa0 ||
	    (unicode > 0x452 && unicode < 0x1100)) {
		// Quickly cover the common cases.
		return NO;
	}

	if ([[NSCharacterSet fullWidthCharacterSetForUnicodeVersion:version] longCharacterIsMember:unicode]) {
		return YES;
	}
	if (ambiguousIsDoubleWidth &&
	    [[NSCharacterSet ambiguousWidthCharacterSetForUnicodeVersion:version] longCharacterIsMember:unicode]) {
		return YES;
	}
	return NO;
}

- (void)enumerateComposedCharacters:(void (^)(NSRange, unichar, NSString *, BOOL *))block {
	if (self.length == 0) {
		return;
	}
	static dispatch_once_t onceToken;
	static NSCharacterSet *exceptions;
	dispatch_once(&onceToken, ^{
		// These characters are forced to be base characters.
		exceptions = [NSCharacterSet characterSetWithCharactersInString:@"\uff9e\uff9f"];
	});
	CFIndex index = 0;
	NSInteger minimumLocation = 0;
	NSRange range;
	do {
		CFRange tempRange = CFStringGetRangeOfComposedCharactersAtIndex((CFStringRef)self, index);
		if (tempRange.location < minimumLocation) {
			NSInteger diff = minimumLocation - tempRange.location;
			tempRange.location += diff;
			if (diff > tempRange.length) {
				tempRange.length = 0;
			} else {
				tempRange.length -= diff;
			}
		}
		range = NSMakeRange(tempRange.location, tempRange.length);
		if (range.length > 0) {
			// CFStringGetRangeOfComposedCharactersAtIndex thinks that U+FF9E and U+FF9F are
			// combining marks. Terminal.app and the person in issue 6048 disagree. Prevent them
			// from combining.
			NSRange rangeOfFirstException = [self rangeOfCharacterFromSet:exceptions
			options:NSLiteralSearch
			range:range];
			if (rangeOfFirstException.location != NSNotFound &&
			    rangeOfFirstException.location > range.location) {
				range.length = rangeOfFirstException.location - range.location;
				minimumLocation = NSMaxRange(range);
			}

			unichar simple = range.length == 1 ? [self characterAtIndex:range.location] : 0;
			NSString *complexString = range.length == 1 ? nil : [self substringWithRange:range];
			BOOL stop = NO;
			block(range, simple, complexString, &stop);
			if (stop) {
				return;
			}
		}
		index = NSMaxRange(range);
	} while (NSMaxRange(range) < self.length);
}

@end
