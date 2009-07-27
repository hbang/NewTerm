// Settings.h
// MobileTerminal

#import <Foundation/Foundation.h>

// TODO(allen): Hard coding this here is less than ideal.  This should probably
// come from an initialization argument from MobileTerminalViewController. 
#define TERMINAL_COUNT 4

@class MenuSettings;
@class TerminalSettings;

// Settings for mobile terminal.  This object implements the NSCoding protocol
// so that the settings can be read and written to the preferences store.
@interface Settings : NSObject <NSCoding> {
@private
  MenuSettings* menuSettings;
  TerminalSettings* terminalSettings[TERMINAL_COUNT];
}

@property(nonatomic, retain) MenuSettings* menuSettings;

+ (Settings*)sharedInstance;

// Read/write the settings from persistent storage
+ (Settings*)readSettings;
+ (void)persistSettings:(Settings*)settings;

- (id)initWithDefaultValues;
- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;

@end
