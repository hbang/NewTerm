// PreferencesViewController.m
// MobileTerminal

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
  NSLog(@"awakeFromNib");
}


- (void)viewDidLoad
{
  [super viewDidLoad];
  NSLog(@"view did load");
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
  
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:itemTitle];
    cell.textLabel.text = itemTitle;
    if ([controllers objectAtIndex:index] != nil) {
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
  }
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSUInteger index = [indexPath indexAtPosition:1];  
  UIViewController* itemController = [controllers objectAtIndex:index];
  [self.navigationController pushViewController:itemController animated:YES];
  itemController.navigationItem.title = [sections objectAtIndex:index];
}

@end

