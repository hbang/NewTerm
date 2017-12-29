//
//  HBNTPreferences.h
//  NewTerm
//
//  Created by Adam Demasi on 21/11/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

#import <Cephei/HBPreferences.h>

@class FontMetrics;

@interface HBNTPreferences : NSObject

+ (instancetype)sharedInstance;

@property (strong, nonatomic, readonly) FontMetrics *fontMetrics;

@end
