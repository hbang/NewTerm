// MobileTerminalAppDelegate.m
// MobileTerminal

#import "MobileTerminalAppDelegate.h"
#import "MobileTerminalViewController.h"

#import "Preferences/PreferencesDataSource.h"
#import "Preferences/Settings.h"
#import "Preferences/MenuSettings.h"


@implementation MobileTerminalAppDelegate

@synthesize window;
@synthesize navigationController;
@synthesize terminalViewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application { 
  settings = [Settings readSettings];
  MenuSettings* menuSettings = [settings menuSettings];
  [menuSettings addItemWithLabel:@"ls" andCommand:@"ls -l"];
  [menuSettings addItemWithLabel:@"ping" andCommand:@"ping"];
  [menuSettings addItemWithLabel:@"^C" andCommand:@"\x03"];
  [[terminalViewController menuView] setMenuSettings:menuSettings];
  
  [[UIApplication sharedApplication] setStatusBarHidden:YES];
  [window addSubview:terminalViewController.view];
  [window makeKeyAndVisible];
}

static const NSTimeInterval kAnimationDuration = 1.00f;

- (void)preferencesButtonPressed
{
  [UIView beginAnimations:NULL context:NULL];
  [UIView setAnimationDuration:kAnimationDuration];
  [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft
                         forView:navigationController.view
                           cache:YES];
  [terminalViewController.view removeFromSuperview];
  [window addSubview:navigationController.view];
  [UIView commitAnimations];
}

- (void)preferencesDonePressed:(id)sender;
{
  [UIView beginAnimations:NULL context:NULL];
  [UIView setAnimationDuration:kAnimationDuration];
  [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight 
                         forView:terminalViewController.view
                           cache:YES];
  
  [navigationController popViewControllerAnimated:YES];
  [navigationController.view removeFromSuperview];
  [window addSubview:terminalViewController.view];
  [UIView commitAnimations];
}

- (void)dealloc {
  [terminalViewController release];
  [window release];
  [super dealloc];
}

@end
