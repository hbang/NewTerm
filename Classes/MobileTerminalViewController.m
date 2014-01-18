// MobileTerminalViewController.m
// MobileTerminal

#import "MobileTerminalViewController.h"

#import "TerminalButton.h"
#import "MenuView.h"
#import "GestureResponder.h"
#import "GestureActionRegistry.h"
#import "Terminal/TerminalController.h"
#import "Terminal/TerminalKeyboard.h"
#import "Terminal/TerminalKeyboard.h"
#import "Terminal/TerminalKeyInput.h"
#import "VT100/VT100TableViewController.h"
#import "VT100/ColorMap.h"
#import "Preferences/Settings.h"
#import "Preferences/TerminalSettings.h"
#import "Preferences/PreferencesRootController.h"

@interface MobileTerminalViewController () {
	BOOL _hasAppeared;
	
	NSMutableArray *_terminals;
	NSInteger _currentTerminalIndex;
	TerminalController *_currentTerminal;
	
	TerminalKeyboard *_terminalKeyboard;
	BOOL _shouldShowKeyboard;
	// If the keyboard is actually shown right now (not if it should be shown)
	BOOL _keyboardShown;
	BOOL _copyPasteEnabled;
	
	UIToolbar *_inputToolbar;
	UIPageControl *_pageControl;
	
	UIPopoverController *_prefsPopoverController;
}

@end

@implementation MobileTerminalViewController

// The designated initializer. Override to perform setup that is required before the view is loaded.
- (void)loadView {
	[super loadView];
	
	self.title = @"MobileTerminal";
	
	self.navigationController.navigationBarHidden = !IS_IPAD;
	self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
	self.navigationController.navigationBar.translucent = YES;
	
	_terminalKeyboard = [[TerminalKeyboard alloc] init];
	_keyboardShown = NO;
	_copyPasteEnabled = NO; // Copy and paste is off by default
	_inputToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 0, IS_IPAD ? 54.f : 38.f)];
	_terminals = [[NSMutableArray alloc] init];
	_pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, 0, 0, 32.f)];
	
	_pageControl.hidesForSinglePage = YES;
	
	CGFloat horizSpacing = IS_IPAD ? 7.f : 4.f;
	CGRect buttonFrame = IS_IPAD ? CGRectMake(horizSpacing, 8.f, 79.f, 38.f) : CGRectMake(horizSpacing, 4.f, 46.f, 30.f);
	CGFloat extra = IS_IPAD ? 14.f : 6.f;
	
	TerminalButton *ctrlButton = [[TerminalButton alloc] initWithFrame:buttonFrame];
	[ctrlButton setTitle:@"Ctrl" forState:UIControlStateNormal];
	[ctrlButton addTarget:self action:@selector(ctrlTapped:) forControlEvents:UIControlEventTouchUpInside];
	[_inputToolbar addSubview:ctrlButton];
	
	buttonFrame.origin.x += buttonFrame.size.width + extra;
	
	TerminalButton *tabButton = [[TerminalButton alloc] initWithFrame:buttonFrame];
	[tabButton setTitle:@"Tab" forState:UIControlStateNormal];
	[tabButton addTarget:self action:@selector(tabTapped:) forControlEvents:UIControlEventTouchUpInside];
	[_inputToolbar addSubview:tabButton];
	
	buttonFrame.origin.x += buttonFrame.size.width + extra;
	
    /* //Todo
    TerminalButton *escButton = [[TerminalButton alloc] initWithFrame:buttonFrame];
	[escButton setTitle:@"Esc" forState:UIControlStateNormal];
	[escButton addTarget:self action:@selector(escTapped:) forControlEvents:UIControlEventTouchUpInside];
	[_inputToolbar addSubview:escButton];
	
	buttonFrame.origin.x += buttonFrame.size.width + extra;
     */
	
	if (!IS_IPAD) {
		buttonFrame.size.width += 12.f;
		buttonFrame.origin.x = _inputToolbar.frame.size.width - horizSpacing - buttonFrame.size.width;
		
		TerminalButton *doneButton = [[TerminalButton alloc] initWithFrame:buttonFrame];
		doneButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		[doneButton setTitle:@"Done" forState:UIControlStateNormal];
		[doneButton addTarget:_terminalKeyboard action:@selector(resignFirstResponder) forControlEvents:UIControlEventTouchUpInside];
		[_inputToolbar addSubview:doneButton];
	}
	
	_inputToolbar.translucent = YES;
	((TerminalKeyInput *)_terminalKeyboard.inputTextField).inputAccessoryView = _inputToolbar;
	
	self.navigationController.toolbarHidden = NO;
	self.navigationController.toolbar.barStyle = UIBarStyleBlack;
	self.navigationController.toolbar.translucent = YES;
	self.toolbarItems = @[
		[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(settingsTapped:)] autorelease],
		[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:Nil action:nil] autorelease],
		[[[UIBarButtonItem alloc] initWithTitle:@"▲" style:UIBarButtonItemStylePlain target:_terminalKeyboard action:@selector(becomeFirstResponder)] autorelease]
	];
	
	for (NSUInteger i = 0; i < TERMINAL_COUNT; i++) {
		[self addTerminal];
	}
	
	[self activateTerminalAtIndex:0];
	[self registerForKeyboardNotifications];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	@try {
		for (TerminalController *controller in _terminals) {
			[controller startSubProcess];
		}
	} @catch (NSException *e) {
		NSLog(@"Caught %@: %@", [e name], [e reason]);
		if ([[e name] isEqualToString:@"ForkException"]) {
			// This happens if we fail to fork for some reason.
			// TODO(allen): Provide a helpful hint -- a kernel patch?
			UIAlertView *view = [[UIAlertView alloc] initWithTitle:e.name message:e.reason delegate:self cancelButtonTitle:@"Exit" otherButtonTitles:NULL];
			[view show];
			return;
		}
		[e raise];
		return;
	}
	
	// TODO(allen):	 This should be configurable
	_shouldShowKeyboard = YES;
	
	// Adding the keyboard to the view has no effect, except that it is will
	// later allow us to make it the first responder so we can show the keyboard
	// on the screen.
	[self.view addSubview:_terminalKeyboard];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	self.showKeyboard = _shouldShowKeyboard;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	return IS_IPAD ? YES : toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)ctrlTapped:(UIButton *)sender {
	TerminalKeyInput *keyInput = (TerminalKeyInput *)_terminalKeyboard.inputTextField;
	keyInput.controlKeyMode = !keyInput.controlKeyMode;
	sender.selected = keyInput.controlKeyMode;
}

- (void)tabTapped:(UIButton *)sender {
	[_currentTerminal receiveKeyboardInput:[NSData dataWithBytes:"\t" length:1]];
}

- (void)addTapped {
	// TODO: implement
}

- (void)settingsTapped:(UIBarButtonItem *)sender {
	PreferencesRootController *prefsRootController = [[[PreferencesRootController alloc] initWithTitle:@"Settings" identifier:[NSBundle mainBundle].infoDictionary[@"CFBundleIdentifier"]] autorelease];
	
	if (IS_IPAD) {
		if (_prefsPopoverController) {
			[_prefsPopoverController dismissPopoverAnimated:YES];
		} else {
			_prefsPopoverController = [[UIPopoverController alloc] initWithContentViewController:prefsRootController];
			_prefsPopoverController.delegate = self;
			[_prefsPopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionRight | UIPopoverArrowDirectionDown animated:YES];
		}
	} else {
		[self.navigationController presentViewController:prefsRootController animated:YES completion:nil];
	}
}

#pragma mark - Terminal management

- (void)addTerminal {
	_pageControl.numberOfPages++;
	
	TerminalController *controller = [[[TerminalController alloc] init] autorelease];
	UITableViewController *viewController = controller.tableViewController;
	
	viewController.tableView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
	viewController.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	viewController.tableView.hidden = YES;
	
	UIEdgeInsets insets = viewController.tableView.contentInset;
	
	insets.top = IS_IPAD && !IS_IOS_7 ? self.navigationController.navigationBar.frame.size.height : 0;
	insets.bottom = self.navigationController.toolbar.frame.size.height;
	
	viewController.tableView.contentInset = insets;
	viewController.tableView.scrollIndicatorInsets = insets;
	
	if (!_keyboardShown && !_hasAppeared) {
		controller.tableViewController.tableView.showsVerticalScrollIndicator = NO;
	}
	
	[self addChildViewController:controller.tableViewController];
	[controller.tableViewController willMoveToParentViewController:self];
	[self.view addSubview:controller.tableViewController.view];
	
	[_terminals addObject:controller];
}

- (void)removeCurrentTerminal {
	[self removeTerminalAtIndex:-1];
}

- (void)removeTerminalAtIndex:(NSUInteger)index {
	_pageControl.numberOfPages--;
	
	// TODO: complete this
	// TerminalController *controller = index == -1 ? _currentTerminal : [_terminals objectAtIndex:index];
	[_terminals removeObjectAtIndex:index];
}

- (void)activateTerminalAtIndex:(NSUInteger)index {
	TerminalController *controller = [_terminals objectAtIndex:index];
	_currentTerminal = controller;
	
	controller.tableViewController.view.hidden = NO;
	_terminalKeyboard.inputDelegate = controller;
	_gestureActionRegistry.terminalInput = controller;
}

#pragma mark - Keyboard management

- (void)registerForKeyboardNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardVisibilityChanged:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardVisibilityChanged:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)unregisterForKeyboardNotifications {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardVisibilityChanged:(NSNotification *)notification {
	VT100TableViewController *viewController = _currentTerminal.tableViewController;
	
	_keyboardShown = !_keyboardShown;
	
	if (!_hasAppeared) {
		_hasAppeared = YES;
		viewController.tableView.showsVerticalScrollIndicator = YES;
	}
	
	self.navigationController.toolbarHidden = _keyboardShown;
	
	UIEdgeInsets insets = viewController.tableView.contentInset;
	CGFloat toolbarHeight = self.navigationController.toolbar.frame.size.height;
	insets.bottom += _keyboardShown ? -toolbarHeight : toolbarHeight;
	
	[UIView animateWithDuration:((NSNumber *)notification.userInfo[UIKeyboardAnimationDurationUserInfoKey]).doubleValue animations:^{
		viewController.tableView.contentInset = insets;
		viewController.tableView.scrollIndicatorInsets = insets;
	}];
}

- (void)setShowKeyboard:(BOOL)showKeyboard {
	if (showKeyboard) {
		[_terminalKeyboard becomeFirstResponder];
	} else {
		[_terminalKeyboard resignFirstResponder];
	}
}

- (void)toggleKeyboard:(id)sender {
	self.showKeyboard = !_keyboardShown;
}

- (void)toggleCopyPaste:(id)sender {
	_copyPasteEnabled = !_copyPasteEnabled;
	_gestureResponder.swipesEnabled = !_copyPasteEnabled;
	
	for (TerminalController *terminal in _terminals) {
		terminal.copyPasteEnabled = _copyPasteEnabled;
	}
}

/*
// Invoked when the page control is clicked to make a new terminal active.	The
// keyboard events are forwarded to the new active terminal and it is made the
// front-most terminal view.
- (void)terminalSelectionDidChange:(id)sender {
	TerminalView *terminalView = _currentTerminal;
	_terminalKeyboard.inputDelegate = terminalView;
	_gestureActionRegistry.terminalInput = terminalView;
	[_terminalGroupView bringTerminalToFront:terminalView];
}

// Invoked when a menu item is clicked, to run the specified command.
- (void)selectedCommand:(NSString *)command {
	TerminalView *terminalView = [_terminalGroupView frontTerminal];
	[terminalView receiveKeyboardInput:[command dataUsingEncoding:NSUTF8StringEncoding]];
	
	// Make the menu disappear
	[_menuView setHidden:YES];
}
*/

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	// User clicked the Exit button below
	exit(0);
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
	[_prefsPopoverController release];
	_prefsPopoverController = nil;
}

#pragma mark - Memory management

- (void)dealloc {
	[_terminalKeyboard release];
	[super dealloc];
}

@end
