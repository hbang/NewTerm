//
//  HBNTTerminalController.h
//  NewTerm
//
//  Created by Adam D on 22/01/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

#import "HBNTTerminalTextView.h"
#import "VT100Types.h"

@class HBNTTerminalSessionViewController, VT100ColorMap, FontMetrics;

@protocol HBNTTerminalControllerDelegate

@required
- (void)refreshWithAttributedString:(NSAttributedString *)attributedString backgroundColor:(UIColor *)backgroundColor;
- (void)activateBell;
- (void)close;

@end

@interface HBNTTerminalController : NSObject <HBNTTerminalKeyboardProtocol>

- (void)startSubProcess;

@property (nonatomic, strong) HBNTTerminalSessionViewController *viewController;
@property (nonatomic) ScreenSize screenSize;
@property (nonatomic, strong, readonly) VT100ColorMap *colorMap;
@property (nonatomic, strong, readonly) FontMetrics *fontMetrics;
@property (nonatomic, readonly) int scrollbackLines;

@property (nonatomic, weak) id <HBNTTerminalControllerDelegate> delegate;

@end
