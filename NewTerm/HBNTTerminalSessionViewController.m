//
//  HBNTTerminalSessionViewController.m
//  NewTerm
//
//  Created by Adam D on 12/12/2014.
//  Copyright (c) 2014 HASHBANG Productions. All rights reserved.
//

#import "HBNTTerminalSessionViewController.h"
#import "HBNTServer.h"

@implementation HBNTTerminalSessionViewController {
	UITextView *_textView;
}

- (instancetype)initWithServer:(HBNTServer *)server {
	self = [self init];
	
	if (self) {
		_server = server;
	}
	
	return self;
}

- (void)loadView {
	[super loadView];
	
	self.title = _server.name;
	
	_textView = [[UITextView alloc] initWithFrame:self.view.bounds];
	_textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_textView.backgroundColor = [UIColor blackColor];
	[self.view addSubview:_textView];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[_textView becomeFirstResponder];
}

@end
