// PreferencesDataSource.m
// MobileTerminal

#import "PreferencesDataSource.h"

@implementation PreferencesDataSource

- (void)pushSectionWithName:(NSString*)sectionName
{
  NSMutableArray* section = [[NSMutableArray alloc] init];
  [section addObject:sectionName];
  [sections addObject:section];
}

- (void)pushItemWithName:(NSString*)itemName
          withController:(UIViewController*)controller
{
  NSMutableArray* section = [sections lastObject];
  NSMutableDictionary* sectionInfo = [[NSMutableDictionary alloc] init];
  [sectionInfo setObject:itemName forKey:@"title"];
  [section addObject:sectionInfo];
}

- (void)addSection:(NSString*)sectionName
{
  [sectionNames addObject:sectionName];
  [sections addObject:[[NSMutableArray alloc] init]];
}

- (id) init
{
  NSLog(@"init");
  self = [super init];
  if (self != nil) {
    // TODO(allen): Link up the controller so they actually do something
    sectionNames = [[NSMutableArray alloc] init];
    sections = [[NSMutableArray alloc] init];
    [self addSection:@"Menu & Gestures"];
    [self pushItemWithName:@"Menu" withController:menuController];
    [self pushItemWithName:@"Gestures" withController:gesturesController];
    [self addSection:@"Terminal Settings"];
    [self pushItemWithName:@"Terminal 1" withController:nil];
    [self pushItemWithName:@"Terminal 2" withController:nil];
    [self pushItemWithName:@"Terminal 3" withController:nil];
    [self pushItemWithName:@"Terminal 4" withController:nil];
    [self addSection:@"Other"];
    [self pushItemWithName:@"About" withController:aboutController];
  }
  return self;
}

- (void) dealloc
{
  [sections release];
  [super dealloc];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return [sectionNames count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
  return [sectionNames objectAtIndex:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSUInteger index = [indexPath indexAtPosition:0];  
  NSUInteger index2 = [indexPath indexAtPosition:1];  
  NSMutableArray* section = [sections objectAtIndex:index];
  NSMutableDictionary* sectionInfo = [section objectAtIndex:index2];
  NSString* itemTitle = [sectionInfo objectForKey:@"title"];
  
  UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:itemTitle];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:itemTitle];
    cell.text = itemTitle;
  }
  return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return [[sections objectAtIndex:section] count];
}

@end
