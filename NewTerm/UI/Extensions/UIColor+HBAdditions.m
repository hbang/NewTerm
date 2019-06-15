#import "UIColor+HBAdditions.h"

@implementation UIColor (HBAdditions)

+ (instancetype)colorWithPropertyListValue:(id)value {
	return [[self alloc] initWithPropertyListValue:value];
}

- (instancetype)initWithPropertyListValue:(id)value {
	if (!value) {
		return nil;
	} else if ([value isKindOfClass:NSArray.class] && ((NSArray *)value).count == 3) {
		NSArray *array = value;
		return [self initWithRed:((NSNumber *)array[0]).integerValue / 255.f
		                   green:((NSNumber *)array[1]).integerValue / 255.f
		                    blue:((NSNumber *)array[2]).integerValue / 255.f
		                   alpha:1];
	} else if ([value isKindOfClass:NSString.class]) {
		NSString *string = value;
		if ([string hasPrefix:@"#"] && (string.length == 7 || string.length == 8 || string.length == 4 || string.length == 5)) {
			if (string.length == 4 || string.length == 5) {
				NSString *r = [string substringWithRange:NSMakeRange(1, 1)];
				NSString *g = [string substringWithRange:NSMakeRange(2, 1)];
				NSString *b = [string substringWithRange:NSMakeRange(3, 1)];
				NSString *a = string.length == 5 ? [string substringWithRange:NSMakeRange(4, 1)] : @"FF";
				string = [NSString stringWithFormat:@"#%1$@%1$@%2$@%2$@%3$@%3$@%4$@%4$@", r, g, b, a];
			}

			unsigned int hex = 0;
			NSScanner *scanner = [NSScanner scannerWithString:string];
			scanner.charactersToBeSkipped = [NSCharacterSet characterSetWithCharactersInString:@"#"];
			[scanner scanHexInt:&hex];

			if (string.length == 8) {
				return [self initWithRed:((hex & 0xFF000000) >> 24) / 255.f
				                   green:((hex & 0x00FF0000) >> 16) / 255.f
				                    blue:((hex & 0x0000FF00) >> 8)  / 255.f
				                   alpha:((hex & 0x000000FF) >> 0)  / 255.f];
			} else {
				return [self initWithRed:((hex & 0xFF0000) >> 16) / 255.f
				                   green:((hex & 0x00FF00) >> 8)  / 255.f
				                    blue:((hex & 0x0000FF) >> 0)  / 255.f
				                   alpha:1];
			}
		}
	}

	return nil;
}

@end
