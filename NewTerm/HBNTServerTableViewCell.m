//
//  HBNTServerTableViewCell.m
//  NewTerm
//
//  Created by Adam D on 12/12/2014.
//  Copyright (c) 2014 HASHBANG Productions. All rights reserved.
//

#import "HBNTServerTableViewCell.h"
#import "HBNTServer.h"

@implementation HBNTServerTableViewCell

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
	self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
	return self;
}

- (void)setServer:(HBNTServer *)server {
	_server = server;
	
	NSString *port = _server.port == 0 || _server.port == 22 ? @"" : [NSString stringWithFormat:@":%i", server.port];
	
	self.textLabel.text = _server.name ?: L18N(@"Untitled");
	self.detailTextLabel.text = _server.isLocalTerminal ? L18N(@"Local Connection") : [NSString stringWithFormat:@"%@@%@%@", _server.username, _server.host, port];
}

@end
