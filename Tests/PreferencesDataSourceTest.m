// PreferencesDataSourceTest.m
// MobileTerminal

#import "PreferencesDataSourceTest.h"

@implementation PreferencesDataSourceTest

- (void) testDataSource {
  PreferencesDataSource* dataSource = [[[PreferencesDataSource alloc] init] retain];
  STAssertEquals(3, [dataSource numberOfSectionsInTableView:nil],
                 @"got %d", [dataSource numberOfSectionsInTableView:nil]);
  
  // Verify the section titles are correct
  STAssertTrue(@"Menu & Gestures" == [dataSource tableView:nil titleForHeaderInSection:0],
                 @"%@", [dataSource tableView:nil titleForHeaderInSection:0]);
  STAssertTrue(@"Terminal Settings" == [dataSource tableView:nil titleForHeaderInSection:1],
                @"%@", [dataSource tableView:nil titleForHeaderInSection:1]);
  STAssertTrue(@"Other" == [dataSource tableView:nil titleForHeaderInSection:2],
               @"%@", [dataSource tableView:nil titleForHeaderInSection:2]);

  STAssertEquals(2, [dataSource tableView:nil numberOfRowsInSection:0],
                 @"got %d", [dataSource tableView:nil numberOfRowsInSection:0]);
  
  // TODO(allen): For some reason, constructing UITableViewCells from the test
  // cases always crashes, making them impossible to test.  Run in a debugger
  // and figure out why its crashing or file a bug.
}
   
@end
