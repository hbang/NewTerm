//
//  HBNTTerminalTextView.h
//  NewTerm
//
//  Created by Adam D on 26/01/2015.
//  Copyright (c) 2015 HASHBANG Productions. All rights reserved.
//

// Protocol implemented by listener of keyboard events
@protocol HBNTTerminalInputProtocol

@required
- (void)receiveKeyboardInput:(NSData *)data;

@end

@protocol HBNTTerminalKeyboardProtocol <HBNTTerminalInputProtocol>

@end

@interface HBNTTerminalTextView : UITextView

@property (strong, nonatomic) id<HBNTTerminalKeyboardProtocol> terminalInputDelegate;

@end
