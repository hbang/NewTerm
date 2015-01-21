//
//  HBNTTerminalSessionViewController.h
//  NewTerm
//
//  Created by Adam D on 12/12/2014.
//  Copyright (c) 2014 HASHBANG Productions. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HBNTServer;

@interface HBNTTerminalSessionViewController : UIViewController

- (instancetype)initWithServer:(HBNTServer *)server;

@property (strong, nonatomic, readonly) HBNTServer *server;

@end
