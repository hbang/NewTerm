// MobileTerminalViewController.m
// MobileTerminal

#import "MobileTerminalViewController.h"

#import "Terminal/TerminalController.h"
#import "Terminal/TerminalKeyboard.h"
#import "VT100/VT100TableViewController.h"
#import "Preferences/Settings.h"
#import "Preferences/TerminalSettings.h"
#import "VT100/ColorMap.h"
#import "MenuView.h"
#import "GestureResponder.h"
#import "GestureActionRegistry.h"

static NSUInteger NumberOfTerminals = 4;

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
}

@end

@implementation MobileTerminalViewController

// The designated initializer. Override to perform setup that is required before the view is loaded.
- (void)loadView {
	[super loadView];
	
	self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
	
	_terminalKeyboard = [[TerminalKeyboard alloc] init];
	_keyboardShown = NO;
	_copyPasteEnabled = NO; // Copy and paste is off by default
	
	_terminals = [[NSMutableArray alloc] init];
	
	for (NSUInteger i = 0; i < NumberOfTerminals; i++) {
		[self addTerminal];
	}
	
	[self activateTerminalAtIndex:0];
	[self registerForKeyboardNotifications];
}

#pragma mark - Terminal management

- (void)addTerminal {
	TerminalSettings *settings = [[Settings sharedInstance] terminalSettings];
	
	TerminalController *controller = [[[TerminalController alloc] init] autorelease];
	controller.tableViewController.view.frame = self.view.frame;
	controller.tableViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	controller.tableViewController.view.hidden = YES;
	controller.tableViewController.font = settings.font;
	
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
	// TODO: complete this
	TerminalController *controller = index == -1 ? _currentTerminal : [_terminals objectAtIndex:index];
	NSLog(@"%@", controller);
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
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardVisibilityChanged:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardVisibilityChanged:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)unregisterForKeyboardNotifications {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
}

- (void)keyboardVisibilityChanged:(NSNotification *)notification {
	_keyboardShown = !_keyboardShown;
	[_currentTerminal.tableViewController scrollToBottomAnimated:YES];
	
	if (!_hasAppeared) {
		_hasAppeared = YES;
		_currentTerminal.tableViewController.tableView.showsVerticalScrollIndicator = YES;
	}
	
	if (IS_IOS_7) {
		UIEdgeInsets insets = _currentTerminal.tableViewController.tableView.contentInset;
		insets.top = self.topLayoutGuide.length;
		_currentTerminal.tableViewController.tableView.contentInset = insets;
		
		UIEdgeInsets scrollInsets = _currentTerminal.tableViewController.tableView.scrollIndicatorInsets;
		scrollInsets.top = self.topLayoutGuide.length;
		_currentTerminal.tableViewController.tableView.scrollIndicatorInsets = scrollInsets;
	}
}

- (void)setShowKeyboard:(BOOL)showKeyboard {
	if (showKeyboard) {
		[_terminalKeyboard becomeFirstResponder];
	} else {
		[_terminalKeyboard resignFirstResponder];
	}
}

- (void)toggleKeyboard:(id)sender {
	[self setShowKeyboard:!_keyboardShown];
}

- (void)toggleCopyPaste:(id)sender {
	_copyPasteEnabled = !_copyPasteEnabled;
	[_gestureResponder setSwipesEnabled:!_copyPasteEnabled];
	for (TerminalController *terminal in _terminals) {
		terminal.copyPasteEnabled = _copyPasteEnabled;
	}
}

// Invoked when the page control is clicked to make a new terminal active.	The
// keyboard events are forwarded to the new active terminal and it is made the
// front-most terminal view.
/*- (void)terminalSelectionDidChange:(id)sender {
	TerminalView *terminalView = _currentTerminal;
	_terminalKeyboard.inputDelegate = terminalView;
	_gestureActionRegistry.terminalInput = terminalView;
	[_terminalGroupView bringTerminalToFront:terminalView];
}

// Invoked when the preferences button is pressed
- (void)preferencesButtonPressed:(id)sender {
	// Remember the keyboard state for the next reload and don't listen for
	// keyboard hide/show events
	_shouldShowKeyboard = _keyboardShown;
	[self unregisterForKeyboardNotifications];
	
	[_interfaceDelegate preferencesButtonPressed];
}

// Invoked when the menu button is pressed
- (void)menuButtonPressed:(id)sender {
	[_menuView setHidden:![_menuView isHidden]];
}

// Invoked when a menu item is clicked, to run the specified command.
- (void)selectedCommand:(NSString *)command {
	TerminalView *terminalView = [_terminalGroupView frontTerminal];
	[terminalView receiveKeyboardInput:[command dataUsingEncoding:NSUTF8StringEncoding]];
	
	// Make the menu disappear
	[_menuView setHidden:YES];
}*/

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	// User clicked the Exit button below
	exit(0);
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
			UIAlertView *view = [[UIAlertView alloc] initWithTitle:[e name] message:[e reason] delegate:self cancelButtonTitle:@"Exit" otherButtonTitles:NULL];
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
	[[self view] addSubview:_terminalKeyboard];
	
	// The menu button points to the right, but for this context it should point
	// up, since the menu moves that way.
	/*_menuButton.transform = CGAffineTransformMakeRotation(-90.0f * M_PI / 180.0f);
	[_menuButton setNeedsLayout];*/
	
	// Setup the page control that selects the active terminal
	/*[_terminalSelector setNumberOfPages:[_terminalGroupView terminalCount]];
	[_terminalSelector setCurrentPage:0];
	// Make the first terminal active
	[self terminalSelectionDidChange:self];*/
}

- (void)viewDidAppear:(BOOL)animated {
	[_interfaceDelegate rootViewDidAppear];
	//[self registerForKeyboardNotifications];
	[self setShowKeyboard:_shouldShowKeyboard];
	
	// Reset the font in case it changed in the preferenes view
	/*TerminalSettings *settings = [[Settings sharedInstance] terminalSettings];
	UIFont *font = [settings font];
	for (int i = 0; i < [_terminalGroupView terminalCount]; ++i) {
		TerminalView *terminalView = [_terminalGroupView terminalAtIndex:i];
		[terminalView setFont:font];
		[terminalView setNeedsLayout];
	}*/
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	return IS_IPAD ? YES : toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)didReceiveMemoryWarning {
	// TODO(allen): Should clear scrollback buffers to save memory?
	[super didReceiveMemoryWarning];
}

- (void)dealloc {
	[_terminalKeyboard release];
	[super dealloc];
}

@end
