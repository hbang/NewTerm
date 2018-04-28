//
//  Created by Marco Arment on 2014-04-06.
//  Copyright (c) 2014 Marco Arment. See included LICENSE file.
//

#import "NSLayoutConstraint+CompactConstraint.h"

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
    #define CCView UIView
#elif TARGET_OS_MAC
    #define CCView NSView
#endif

@interface CCView (CompactConstraint)

// Add a single constraint with the compact syntax
- (NSLayoutConstraint *)addCompactConstraint:(NSString *)relationship metrics:(NSDictionary *)metrics views:(NSDictionary *)views;

// Add any number of constraints. Can also mix in Visual Format Language strings.
- (NSArray *)addCompactConstraints:(NSArray *)relationshipStrings metrics:(NSDictionary *)metrics views:(NSDictionary *)views;

// And a convenient shortcut for what we always end up doing with the visualFormat call.
- (void)addConstraintsWithVisualFormat:(NSString *)format options:(NSLayoutFormatOptions)opts metrics:(NSDictionary *)metrics views:(NSDictionary *)views;

@end
