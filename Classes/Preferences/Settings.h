// Settings.h
// MobileTerminal

#import <Foundation/Foundation.h>

// TODO(allen): Hard coding this here is less than ideal.  This should probably
// come from an initialization argument from MobileTerminalViewController. 
#define TEMRINAL_COUNT 4

@class TerminalSettings;

// Settings for mobile terminal.  This object implements the NSCoding protocol
// so that the settings can be read and written to the preferences store.
@interface Settings : NSObject <NSCoding> {
@private
  TerminalSettings* terminal[TERMINAL_COUNT];
}

- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;

@end
