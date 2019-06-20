//
//  NSCharacterSet+iTerm.h
//  iTerm2
//
//  Created by George Nachman on 3/29/15.
//
//

@import Foundation;

@interface NSCharacterSet (iTerm)

+ (instancetype)fullWidthCharacterSetForUnicodeVersion:(NSInteger)version;
+ (instancetype)ambiguousWidthCharacterSetForUnicodeVersion:(NSInteger)version;
+ (instancetype)zeroWidthSpaceCharacterSet;

@end
