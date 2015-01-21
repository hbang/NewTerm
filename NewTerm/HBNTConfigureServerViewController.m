//
//  HBNTAddServerViewController.m
//  NewTerm
//
//  Created by Adam D on 21/07/2014.
//  Copyright (c) 2014 HASHBANG Productions. All rights reserved.
//

#import "HBNTConfigureServerViewController.h"
#import "HBNTTextFieldTableViewCell.h"
#import "HBNTHostTableViewCell.h"
#import "HBNTSegmentTableViewCell.h"
#import "HBNTServer.h"

@implementation HBNTConfigureServerViewController {
	HBNTServerAuthenticationType _authenticationType;
}

- (void)loadView {
	[super loadView];
	
	self.title = L18N(@"Add Server");
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (indexPath.section) {
		case 0:
			switch (indexPath.row) {
				case 0:
				{
					static NSString *CellIdentifier = @"HostCell";
					HBNTHostTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
					
					if (!cell) {
						cell = [[HBNTHostTableViewCell alloc] initWithReuseIdentifier:CellIdentifier];
						cell.textLabel.text = L18N(@"Host");
					}
					
					cell.textField.enabled = !_server.isLocalTerminal;
					cell.textField.placeholder = @"example.com";
					
					cell.portTextField.enabled = !_server.isLocalTerminal;
					cell.portTextField.placeholder = @"22";
					
					if (_server.isLocalTerminal) {
						cell.textField.text = L18N(@"Local Connection");
						cell.portTextField.text = @" ";
					} else {
						cell.textField.text = _server.host ?: @"";
						cell.portTextField.text = @(_server.port).stringValue ?: @"22";
					}
					
					return cell;
					break;
				}
				
				case 1:
				{
					static NSString *CellIdentifier = @"TextFieldCell";
					HBNTTextFieldTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
					
					if (!cell) {
						cell = [[HBNTTextFieldTableViewCell alloc] initWithReuseIdentifier:CellIdentifier];
					}
					
					cell.textLabel.text = L18N(@"Username");
					
					cell.textField.enabled = !_server.isLocalTerminal;
					cell.textField.text = _server.username;
					cell.textField.placeholder = @"awesome";
					
					return cell;
					break;
				}
			}
			
			break;
		
		case 1:
			switch (indexPath.row) {
				case 0:
				{
					static NSString *CellIdentifier = @"SegmentCell";
					HBNTSegmentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
					
					if (!cell) {
						cell = [[HBNTSegmentTableViewCell alloc] initWithReuseIdentifier:CellIdentifier];
						[cell.segmentControl insertSegmentWithTitle:L18N(@"Password") atIndex:0 animated:NO];
						[cell.segmentControl insertSegmentWithTitle:L18N(@"Key") atIndex:1 animated:NO];
					}
					
					cell.segmentControl.enabled = !_server.isLocalTerminal;
					cell.segmentControl.selectedSegmentIndex = _authenticationType;
					
					return cell;
				}
					
				case 1:
				{
					static NSString *CellIdentifier = @"TextFieldCell";
					HBNTTextFieldTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
					
					if (!cell) {
						cell = [[HBNTTextFieldTableViewCell alloc] initWithReuseIdentifier:CellIdentifier];
					}
					
					cell.textLabel.text = L18N(@"Password");
					
					cell.textField.enabled = !_server.isLocalTerminal;
					cell.textField.placeholder = @"correcthorsebatterystaple";
					cell.textField.text = @""; // TODO
					cell.textField.secureTextEntry = YES;
					
					return cell;
					break;
				}
			}
			
			return nil;
			break;
	}
	
	return nil;
}

#pragma mark - Actions

- (IBAction)cancelTapped {
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)doneTapped {
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
