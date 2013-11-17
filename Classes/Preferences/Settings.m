// Settings.m
// MobileTerminal

#import "Settings.h"
#import "GestureSettings.h"
#import "MenuSettings.h"
#import "TerminalSettings.h"

/*
static NSString *kDefaultMenuItems[][2] = {
	{ @"ls", @"ls" },
	{ @"ls -l", @"ls -l\n" },
	{ @"ssh", @"ssh " },
	{ @"locate", @"locate" },
	{ @"ping www.google.com", @"ping www.google.com\n" },
	{ @"^C", @"\x03" },
};
static int kDefaultMenuItemsCount = sizeof(kDefaultMenuItems) / sizeof(NSString *) / 2;
*/

void PreferencesDidChange() {
	[[Settings sharedInstance] reload];
}

@implementation Settings

+ (instancetype)sharedInstance {
	static Settings *sharedInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstance = [[self.class alloc] init];
	});
	
	return sharedInstance;
}

- (instancetype)init {
	self = [super init];
	
	if (self) {
		_menuSettings = [[MenuSettings alloc] init];
		_gestureSettings = [[GestureSettings alloc] init];
		_terminalSettings = [[TerminalSettings alloc] init];
		
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)PreferencesDidChange, CFSTR("ws.hbang.Terminal/ReloadPrefs"), NULL, 0);
	}
	
	return self;
}

- (void)reload {
	[_terminalSettings reload];
}

/*
- (void)initDefaultMenuSettings {
	// TODO(allen): Put defaults values in an XML file.	 Maybe using an XML file
	// would have been better than using NSUserDefaults.
	for (int i = 0; i < kDefaultMenuItemsCount; ++i) {
		MenuItem *menuItem = [MenuItem newItemWithLabel:kDefaultMenuItems[i][0] andCommand:kDefaultMenuItems[i][1]];
		[_menuSettings addMenuItem:menuItem];
		[menuItem release];
	}
}

- (void)initDefaultGestureSettings {
	// Initialize the defaults from the .plist file.
	NSDictionary *defaultLabels = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GestureDefaults" ofType:@"plist"]];
	for (int i = 0; i < _gestureSettings.gestureItemCount; ++i) {
		GestureItem *item = [_gestureSettings gestureItemAtIndex:i];
		NSString *actionLabel = [[defaultLabels objectForKey:item.name] retain];
		
		if (actionLabel) {
			item.actionLabel = actionLabel;
		}
		
		[actionLabel release];
	}
}
*/

- (void)dealloc {
	[_menuSettings release];
	[_gestureSettings release];
	[_terminalSettings release];
	[super dealloc];
}

@end
