#import "UIColor+HBAdditions.h"

@implementation Color (HBAdditions)

+ (instancetype)colorWithPropertyListValue:(id)value {
	return [[self alloc] initWithPropertyListValue:value];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype)initWithPropertyListValue:(id)value {
	CGFloat r = 0, g = 0, b = 0, a = 0;

	if (!value) {
		return nil;
	} else if ([value isKindOfClass:NSArray.class] && ((NSArray *)value).count == 3) {
		NSArray *array = value;
		r = ((NSNumber *)array[0]).integerValue / 255.f;
		g = ((NSNumber *)array[1]).integerValue / 255.f;
		b = ((NSNumber *)array[2]).integerValue / 255.f;
		a = 1;
	} else if ([value isKindOfClass:NSString.class]) {
		NSString *string = value;
		if ([string hasPrefix:@"#"] && (string.length == 7 || string.length == 8 || string.length == 4 || string.length == 5)) {
			if (string.length == 4 || string.length == 5) {
				NSString *r2 = [string substringWithRange:NSMakeRange(1, 1)];
				NSString *g2 = [string substringWithRange:NSMakeRange(2, 1)];
				NSString *b2 = [string substringWithRange:NSMakeRange(3, 1)];
				NSString *a2 = string.length == 5 ? [string substringWithRange:NSMakeRange(4, 1)] : @"FF";
				string = [NSString stringWithFormat:@"#%1$@%1$@%2$@%2$@%3$@%3$@%4$@%4$@", r2, g2, b2, a2];
			}

			unsigned int hex = 0;
			NSScanner *scanner = [NSScanner scannerWithString:string];
			scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@"#"];
			[scanner scanHexInt:&hex];

			if (string.length == 8) {
				r = ((hex & 0xFF000000) >> 24) / 255.f;
				g = ((hex & 0x00FF0000) >> 16) / 255.f;
				b = ((hex & 0x0000FF00) >> 8)  / 255.f;
				a = ((hex & 0x000000FF) >> 0)  / 255.f;
			} else {
				r = ((hex & 0xFF0000) >> 16) / 255.f;
				g = ((hex & 0x00FF00) >> 8)  / 255.f;
				b = ((hex & 0x0000FF) >> 0)  / 255.f;
				a = 1;
			}
		} else {
			return nil;
		}
	} else {
		return nil;
	}

#if TARGET_OS_IPHONE
	return [UIColor colorWithRed:r green:g blue:b alpha:a];
#else
	return [NSColor colorWithSRGBRed:r green:g blue:b alpha:a];
#endif
}
#pragma clang diagnostic pop

@end
