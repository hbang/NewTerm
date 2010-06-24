//
//  PreferencesViewController.m
//  MobileTerminal
//
//  Created by Allen Porter on 6/23/10.
//  Copyright 2010 thebends. All rights reserved.
//

#import "PreferencesViewController.h"


@implementation PreferencesViewController

@synthesize navigationController;
@synthesize terminalSettingsController;
@synthesize menuSettingsController;
@synthesize gestureSettingsController;
@synthesize aboutController;

#pragma mark -
#pragma mark Initialization

- (void)awakeFromNib
{
  [super awakeFromNib];

  sections = [[NSMutableArray alloc] init];
  controllers = [[NSMutableArray alloc] init];
  [sections addObject:@"Terminal Settings"];
  [sections addObject:@"Shortcut Menu"];
  [sections addObject:@"Gestures"];
  [sections addObject:@"About"];
  [controllers addObject:terminalSettingsController];
  [controllers addObject:menuSettingsController];
  [controllers addObject:gestureSettingsController];
  [controllers addObject:aboutController];      
}

- (void)dealloc
{
  [super dealloc];
  [sections dealloc];
  [controllers dealloc];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return [sections count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSUInteger index = [indexPath indexAtPosition:1];  
  NSString* itemTitle = [sections objectAtIndex:index];
  
  UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:itemTitle];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:itemTitle];
    cell.textLabel.text = itemTitle;
    if ([controllers objectAtIndex:index] != nil) {
      cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
  }
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSLog(@"didSelectRowAtIndexPath");
  NSUInteger index = [indexPath indexAtPosition:1];  
  UIViewController* itemController = [controllers objectAtIndex:index];
  [self.navigationController pushViewController:itemController animated:YES];
}

@end

