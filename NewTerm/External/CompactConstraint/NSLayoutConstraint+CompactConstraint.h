//
//  Created by Marco Arment on 2014-04-06.
//  Copyright (c) 2014 Marco Arment. See included LICENSE file.
//

#import "TargetConditionals.h" 

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

@interface NSLayoutConstraint (CompactConstraint)

+ (instancetype)compactConstraint:(NSString *)relationship metrics:(NSDictionary <NSString *, NSNumber *> *)metrics views:(NSDictionary <NSString *, UIView *> *)views self:(id)selfView;
+ (NSArray <NSLayoutConstraint *> *)compactConstraints:(NSArray <NSString *> *)relationshipStrings metrics:(NSDictionary <NSString *, NSNumber *> *)metrics views:(NSDictionary <NSString *, UIView *> *)views self:(id)selfView;

// And a convenient shortcut for creating constraints with the visualFormat string as the identifier
+ (NSArray <NSLayoutConstraint *> *)identifiedConstraintsWithVisualFormat:(NSString *)format options:(NSLayoutFormatOptions)opts metrics:(NSDictionary <NSString *, NSNumber *> *)metrics views:(NSDictionary <NSString *, UIView *> *)views;

// Deprecated, will be removed shortly:
+ (instancetype)compactConstraint:(NSString *)relationship metrics:(NSDictionary <NSString *, NSNumber *> *)metrics views:(NSDictionary <NSString *, UIView *> *)views       __attribute__ ((deprecated));
+ (NSArray <NSLayoutConstraint *> *)compactConstraints:(NSArray <NSString *> *)relationshipStrings metrics:(NSDictionary <NSString *, NSNumber *> *)metrics views:(NSDictionary <NSString *, UIView *> *)views   __attribute__ ((deprecated));

@end
