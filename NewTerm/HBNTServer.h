//
//  HBNTServer.h
//  NewTerm
//
//  Created by Adam D on 21/07/2014.
//  Copyright (c) 2014 HASHBANG Productions. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, HBNTServerAuthenticationType) {
	HBNTServerAuthenticationTypePassword,
	HBNTServerAuthenticationTypeKey
};

@interface HBNTServer : NSObject

+ (instancetype)localServer;

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *host; // nil = local
@property unsigned short port;
@property (getter=isLocalTerminal) BOOL localTerminal;

@property (strong, nonatomic) NSString *username;
@property (strong, nonatomic) NSString *privateKeyName;
@property HBNTServerAuthenticationType authenticationType;

@end
