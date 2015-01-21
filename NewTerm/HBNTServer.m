//
//  HBNTServer.m
//  NewTerm
//
//  Created by Adam D on 21/07/2014.
//  Copyright (c) 2014 HASHBANG Productions. All rights reserved.
//

#import "HBNTServer.h"

@implementation HBNTServer

- (instancetype)init {
	self = [super init];
	
	if (self) {
		_port = 22;
	}
	
	return self;
}

@end
