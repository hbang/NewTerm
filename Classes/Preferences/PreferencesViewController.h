// PreferencesViewController.h
// MobileTerminal

#import <UIKit/UIKit.h>


@interface PreferencesViewController : UITableViewController {
@private
  UINavigationController* navigationController;  
  UIViewController* menuSettingsController;
  UIViewController* gestureSettingsController;
  UIViewController* aboutController;
  
  NSMutableArray* sections;
  NSMutableArray* controllers;
}

@property(nonatomic, retain) IBOutlet UINavigationController* navigationController;
@property(nonatomic, retain) IBOutlet UIViewController* menuSettingsController;
@property(nonatomic, retain) IBOutlet UIViewController* gestureSettingsController;
@property(nonatomic, retain) IBOutlet UIViewController* aboutController;

@end
