//
//  HBNTServer.m
//  NewTerm
//
//  Created by Adam D on 21/07/2014.
//  Copyright (c) 2014 HASHBANG Productions. All rights reserved.
//

#import "HBNTServer.h"

@implementation HBNTServer

+ (instancetype)localServer {
	static HBNTServer *localServer;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		localServer = [[HBNTServer alloc] init];
		localServer.name = [UIDevice currentDevice].name;
		localServer.username = @"mobile";
		localServer.localTerminal = YES;
	});
	
	return localServer;
}

- (instancetype)init {
	self = [super init];
	
	if (self) {
		_port = 22;
	}
	
	return self;
}

@end
