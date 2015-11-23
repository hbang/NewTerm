//
//  HBNTPreferences.h
//  NewTerm
//
//  Created by Adam Demasi on 21/11/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

@class FontMetrics;

@interface HBNTPreferences : NSObject

+ (instancetype)sharedInstance;

@property (strong, nonatomic, readonly) FontMetrics *fontMetrics;

@end
