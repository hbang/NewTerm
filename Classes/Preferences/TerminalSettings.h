// TerminalSettings.h
// MobileTerminal

#import <Foundation/Foundation.h>

static NSString *const TerminalSettingsDidChange = @"TerminalSettingsDidChange";

@class ColorMap, UIFont;

// Settings that apply to a terminal.
@interface TerminalSettings : NSObject

- (void)reload;

@property (nonatomic, retain) UIFont *font;
@property (nonatomic, retain) ColorMap *colorMap;
@property (nonatomic, retain) NSString *arguments;

@end
