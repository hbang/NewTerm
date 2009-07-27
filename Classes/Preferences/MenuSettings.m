// MenuSettings.m
// MobileTerminal

#import "MenuSettings.h"


@implementation MenuSettings

static NSString* kLabelsKey = @"labels";
static NSString* kCommandsKeys = @"commands";

- (id) init
{
  return [self initWithCoder:nil];
}

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if (self != nil) {
    if ([decoder containsValueForKey:kLabelsKey] &&
        [decoder containsValueForKey:kCommandsKeys]) {
      labels = [[decoder decodeObjectForKey:kLabelsKey] retain];
      commands = [[decoder decodeObjectForKey:kCommandsKeys] retain];
    }
    if (labels == nil || commands == nil || [labels count] != [commands count]) {
      [labels release];
      [commands release];
      
      labels = [[NSMutableArray alloc] init];
      commands = [[NSMutableArray alloc] init];
    }
  }
  return self;
}

- (void) dealloc
{
  [labels release];
  [commands release];
  [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:labels forKey:kLabelsKey];
  [encoder encodeObject:commands forKey:kCommandsKeys];
}

- (int)count
{
  return [labels count];
}

- (NSString*)itemLabelAtIndex:(int)index
{
  return [labels objectAtIndex:index];
}

- (NSString*)itemCommandAtIndex:(int)index
{
  return [commands objectAtIndex:index];
}

- (void)addItemWithLabel:(NSString*)label andCommand:(NSString*)command
{
  [labels addObject:label];
  [commands addObject:command];
}


@end
