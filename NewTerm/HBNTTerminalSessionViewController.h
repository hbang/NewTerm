//
//  HBNTTerminalSessionViewController.h
//  NewTerm
//
//  Created by Adam D on 12/12/2014.
//  Copyright (c) 2014 HASHBANG Productions. All rights reserved.
//

#import "VT100Types.h"

@class VT100ColorMap;

@interface HBNTTerminalSessionViewController : UIViewController <ScreenBufferRefreshDelegate>

- (void)readInputStream:(NSData *)data;
- (void)clearScreen;

@property (strong, nonatomic, readonly) UITextView *textView;

@property (strong, nonatomic) UIFont *font;
@property (strong, nonatomic) VT100ColorMap *colorMap;

@property (nonatomic, readonly) int screenWidth;
@property (nonatomic, readonly) int screenHeight;

@end
