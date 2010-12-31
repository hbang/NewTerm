// MenuSettings.m
// MobileTerminal

#import "MenuSettings.h"

@implementation MenuItem

static NSString* kLabelKey = @"label";
static NSString* kCommandKey = @"command";

@synthesize label;
@synthesize command;

- (id)initWithLabel:(NSString*)aLabel andCommand:(NSString*)aCommand;
{
  self = [super init];
  if (self != nil) {
    label = aLabel;
    command = aCommand;
  }
  return self;
}

+ (MenuItem*)newItemWithLabel:(NSString*)aLabel andCommand:(NSString*)aCommand;
{
  return [[MenuItem alloc] initWithLabel:aLabel andCommand:aCommand];
}

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if (self != nil) {
    if ([decoder containsValueForKey:kLabelKey] &&
        [decoder containsValueForKey:kCommandKey]) {
      label = [[decoder decodeObjectForKey:kLabelKey] retain];
      command = [[decoder decodeObjectForKey:kCommandKey] retain];
    }
    if (label == nil || command == nil) {
      [label release];
      [command release];
      label = @"";
      command = @"";
    }
  }
  return self;
}

- (void) dealloc
{
  [label release];
  [command release];
  [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:label forKey:kLabelKey];
  [encoder encodeObject:command forKey:kCommandKey];
}

@end

@implementation MenuSettings

static NSString* kMenuItemsKey = @"menuitems";

- (id) init
{
  return [self initWithCoder:nil];
}

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if (self != nil) {
    if ([decoder containsValueForKey:kMenuItemsKey]) {
      menuItems = [[decoder decodeObjectForKey:kMenuItemsKey] retain];
    }
    if (menuItems == nil) {
      menuItems = [[NSMutableArray alloc] init];
    }
  }
  return self;
}

- (void) dealloc
{
  [menuItems release];
  [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:menuItems forKey:kMenuItemsKey];
}

- (int)menuItemCount
{
  return [menuItems count];
}

- (MenuItem*)menuItemAtIndex:(int)index
{
  return [menuItems objectAtIndex:index];
}

- (void)addMenuItem:(MenuItem*)menuItem
{
  [menuItems addObject:menuItem];
}

- (void)removeMenuItemAtIndex:(int)index
{
  [menuItems removeObjectAtIndex:index];
}

@end
