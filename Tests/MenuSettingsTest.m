// MenuSettingsTest
// MobileTerminal

#import "MenuSettingsTest.h"
#import "MenuSettings.h"

@implementation MenuSettingsTest

- (void) setUp
{
  menuSettings = [[MenuSettings alloc] init];
}

- (void) tearDown
{
  [menuSettings release];
}


- (void) testMenuSettings
{
  STAssertEquals(0, [menuSettings menuItemCount],
                @"got %d", [menuSettings menuItemCount]);
  [menuSettings addMenuItem:[MenuItem itemWithLabel:@"item1" andCommand:@"command1"]];
  STAssertEquals(1, [menuSettings menuItemCount],
                 @"got %d", [menuSettings menuItemCount]);
  STAssertTrue([@"item1" isEqualToString:[[menuSettings menuItemAtIndex:0] label]],
               @"got %@", [[menuSettings menuItemAtIndex:0] label]);
  STAssertTrue([@"command1" isEqualToString:[[menuSettings menuItemAtIndex:0] command]],
               @"got %@", [[menuSettings menuItemAtIndex:0] command]);
  
  [menuSettings addMenuItem:[MenuItem itemWithLabel:@"item2" andCommand:@"command2"]];
  STAssertEquals(2, [menuSettings menuItemCount],
                 @"got %d", [menuSettings menuItemCount]);
  STAssertTrue([@"item1" isEqualToString:[[menuSettings menuItemAtIndex:0] label]],
               @"got %@", [[menuSettings menuItemAtIndex:0] label]);
  STAssertTrue([@"command1" isEqualToString:[[menuSettings menuItemAtIndex:0] command]],
               @"got %@", [[menuSettings menuItemAtIndex:0] command]);
  STAssertTrue([@"item2" isEqualToString:[[menuSettings menuItemAtIndex:1] label]],
               @"got %@", [[menuSettings menuItemAtIndex:1] label]);
  STAssertTrue([@"command2" isEqualToString:[[menuSettings menuItemAtIndex:1] command]],
               @"got %@", [[menuSettings menuItemAtIndex:1] command]);
  
  // Encode and decode the settings
  NSData* data = [NSKeyedArchiver archivedDataWithRootObject:menuSettings]; 
  MenuSettings* newMenuSettings = [[NSKeyedUnarchiver unarchiveObjectWithData:data] retain];
  STAssertTrue([@"item1" isEqualToString:[[newMenuSettings menuItemAtIndex:0] label]],
               @"got %@", [[newMenuSettings menuItemAtIndex:0] label]);
  STAssertTrue([@"command1" isEqualToString:[[newMenuSettings menuItemAtIndex:0] command]],
               @"got %@", [[newMenuSettings menuItemAtIndex:0] command]);
  STAssertTrue([@"item2" isEqualToString:[[newMenuSettings menuItemAtIndex:1] label]],
               @"got %@", [[newMenuSettings menuItemAtIndex:1] label]);
  STAssertTrue([@"command2" isEqualToString:[[newMenuSettings menuItemAtIndex:1] command]],
               @"got %@", [[newMenuSettings menuItemAtIndex:1] command]);
}

@end
