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
  STAssertEquals(0, [menuSettings count],
                @"got %d", [menuSettings count]);
  [menuSettings addItemWithLabel:@"item1" andCommand:@"command1"];
  STAssertEquals(1, [menuSettings count],
                 @"got %d", [menuSettings count]);
  STAssertTrue([@"item1" isEqualToString:[menuSettings itemLabelAtIndex:0]],
               @"got %@", [menuSettings itemLabelAtIndex:0]);
  STAssertTrue([@"command1" isEqualToString:[menuSettings itemCommandAtIndex:0]],
               @"got %@", [menuSettings itemCommandAtIndex:0]);
  
  [menuSettings addItemWithLabel:@"item2" andCommand:@"command2"];
  STAssertEquals(2, [menuSettings count],
                 @"got %d", [menuSettings count]);
  STAssertTrue([@"item1" isEqualToString:[menuSettings itemLabelAtIndex:0]],
               @"got %@", [menuSettings itemLabelAtIndex:0]);
  STAssertTrue([@"command1" isEqualToString:[menuSettings itemCommandAtIndex:0]],
               @"got %@", [menuSettings itemCommandAtIndex:0]);
  STAssertTrue([@"item2" isEqualToString:[menuSettings itemLabelAtIndex:1]],
               @"got %@", [menuSettings itemLabelAtIndex:1]);
  STAssertTrue([@"command2" isEqualToString:[menuSettings itemCommandAtIndex:1]],
               @"got %@", [menuSettings itemCommandAtIndex:1]);

  // Encode and decode the settings
  NSData* data = [NSKeyedArchiver archivedDataWithRootObject:menuSettings]; 
  MenuSettings* newMenuSettings = [[NSKeyedUnarchiver unarchiveObjectWithData:data] retain];
  STAssertEquals(2, [newMenuSettings count],
                 @"got %d", [newMenuSettings count]);
  STAssertTrue([@"item1" isEqualToString:[newMenuSettings itemLabelAtIndex:0]],
               @"got %@", [newMenuSettings itemLabelAtIndex:0]);
  STAssertTrue([@"command1" isEqualToString:[newMenuSettings itemCommandAtIndex:0]],
               @"got %@", [newMenuSettings itemCommandAtIndex:0]);
  STAssertTrue([@"item2" isEqualToString:[newMenuSettings itemLabelAtIndex:1]],
               @"got %@", [newMenuSettings itemLabelAtIndex:1]);
  STAssertTrue([@"command2" isEqualToString:[newMenuSettings itemCommandAtIndex:1]],
               @"got %@", [newMenuSettings itemCommandAtIndex:1]);  
}

@end
