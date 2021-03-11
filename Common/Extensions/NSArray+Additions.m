//
//  NSArray+Additions.m
//  NewTerm
//
//  Created by Adam Demasi on 23/3/18.
//  Copyright © 2018 HASHBANG Productions. All rights reserved.
//

#import "NSArray+Additions.h"

@implementation NSArray (Additions)

- (char **)cStringArray {
	// This is in objc because it’s impossibly complex to do this in Swift…
	NSUInteger count = self.count + 1;
	char **result = malloc(sizeof(char *) * count);

	for (NSUInteger i = 0; i < self.count; i++) {
		NSString *item = [self[i] isKindOfClass:NSString.class] ? self[i] : ((NSObject *)self[i]).description;
		result[i] = (char *)item.UTF8String;
	}

	result[count - 1] = NULL;
	return result;
}

@end
