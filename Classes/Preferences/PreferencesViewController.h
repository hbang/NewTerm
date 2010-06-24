//
//  PreferencesViewController.h
//  MobileTerminal
//
//  Created by Allen Porter on 6/23/10.
//  Copyright 2010 thebends. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface PreferencesViewController : UITableViewController {
@private
  UINavigationController* navigationController;  
  UIViewController* terminalSettingsController;
  UIViewController* menuSettingsController;
  UIViewController* gestureSettingsController;
  UIViewController* aboutController;
  
  NSMutableArray* sections;
  NSMutableArray* controllers;
}

@property(nonatomic, retain) IBOutlet UINavigationController* navigationController;
@property(nonatomic, retain) IBOutlet UIViewController* terminalSettingsController;
@property(nonatomic, retain) IBOutlet UIViewController* menuSettingsController;
@property(nonatomic, retain) IBOutlet UIViewController* gestureSettingsController;
@property(nonatomic, retain) IBOutlet UIViewController* aboutController;

@end
