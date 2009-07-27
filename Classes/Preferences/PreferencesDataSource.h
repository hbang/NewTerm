// PreferencesDataSource.h
// MobileTerminal

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// PreferencesDataSource provides the data for the UITableView that displays
// preferences.  This does not storage the actual preferences, just the stuff
// shown in the UI.
@interface PreferencesDataSource : NSObject<UITableViewDataSource> {
@private
  UIViewController* menuController;
  UIViewController* gesturesController;
  UIViewController* aboutController;
  
  NSMutableArray* sectionNames;
  NSMutableArray* sections;
}

- (id)init;

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;

@end
