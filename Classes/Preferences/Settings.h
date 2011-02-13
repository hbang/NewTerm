// Settings.h
// MobileTerminal

#import <Foundation/Foundation.h>

// TODO(allen): Hard coding this here is less than ideal.  This should probably
// come from an initialization argument from MobileTerminalViewController. 
#define TERMINAL_COUNT 4

@class MenuSettings;
@class TerminalSettings;
@class GestureSettings;

// Settings for mobile terminal.  This object implements the NSCoding protocol
// so that the settings can be read and written to the preferences store.
@interface Settings : NSObject <NSCoding> {
@private
  int svnVersion;
  MenuSettings* menuSettings;
  GestureSettings* gestureSettings;
  TerminalSettings* terminalSettings;
}

@property(nonatomic) int svnVersion;
@property(nonatomic, retain) MenuSettings* menuSettings;
@property(nonatomic, retain) GestureSettings* gestureSettings;
@property(nonatomic, retain) TerminalSettings* terminalSettings;


+ (Settings*)sharedInstance;

// Write the settings to persistent storage
- (void)persist;

- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;

@end
