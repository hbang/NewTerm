// MenuSettingsViewController.m
// MobileTerminal

#import "MenuSettingsViewController.h"

#import "Settings.h"
#import "MenuEditViewController.h"
#import "MenuSettings.h"

@implementation MenuSettingsViewController

@synthesize menuEditViewController;

- (void)awakeFromNib
{
  [super awakeFromNib];
  
  menuSettings = [[Settings sharedInstance] menuSettings];
  
  // Display the insert button
  UIBarButtonItem *addButtonItem =
      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addItem:)];
  self.navigationItem.rightBarButtonItem = addButtonItem;
  [addButtonItem release];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return [menuSettings menuItemCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{  
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
  }
  int index = [indexPath indexAtPosition:1];
  MenuItem* menuItem = [menuSettings menuItemAtIndex:index];
  cell.textLabel.text = menuItem.label;
  cell.detailTextLabel.text = menuItem.command;
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
  int index = [indexPath indexAtPosition:1];
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    [menuSettings removeMenuItemAtIndex:index];
    [self.tableView reloadData];
  }
}

- (void)addItem:(id)sender
{
  [self.tableView reloadData];
  [self startEditing:[MenuItem newItemWithLabel:@"" andCommand:@""] asInsert:TRUE];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  int index = [indexPath indexAtPosition:1];  
  [self startEditing:[menuSettings menuItemAtIndex:index] asInsert:FALSE];
}

- (void)startEditing:(MenuItem*)menuItem asInsert:(BOOL)isInsert
{
  editIsInsert = isInsert;
  menuEditViewController.editingMenuItem = menuItem;
  [self.navigationController pushViewController:menuEditViewController animated:YES];
}

- (void)finishEditing:(id)sender
{
  if (editIsInsert) {
    [menuSettings addMenuItem:menuEditViewController.editingMenuItem];
  }
  [self.tableView reloadData];
}

@end

