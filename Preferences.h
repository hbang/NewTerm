@class PSRootController, PSSpecifier, PSListController;

@interface PSRootController : UINavigationController

- (instancetype)initWithTitle:(NSString *)title identifier:(NSString *)identifier;
- (void)pushController:(PSListController *)controller;

@property (nonatomic, retain) UIView *contentView;

@end

@interface PSSpecifier : NSObject

@property (nonatomic, retain) id target;
@property (nonatomic, retain) NSString *name;

@end

@interface PSListController : UIViewController {
	NSArray *_specifiers;
}

- (instancetype)initForContentSize:(CGSize)contentSize;
- (NSArray *)loadSpecifiersFromPlistName:(NSString *)name target:(PSListController *)target;
- (void)viewWillBecomeVisible:(PSSpecifier *)specifier;

@property (nonatomic, retain) PSRootController *rootController;
@property (nonatomic, retain) UIViewController *parentController;
@property (nonatomic, retain) PSSpecifier *specifier;

@end
