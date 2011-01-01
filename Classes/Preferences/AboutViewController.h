// AboutViewController.h
// MobileTerminal

#import <UIKit/UIKit.h>


@interface AboutViewController : UIViewController {
@private
  UILabel* versionLabel;
}

@property(nonatomic, retain) IBOutlet UILabel* versionLabel;


@end
