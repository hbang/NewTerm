// Settings.m
// MobileTerminal

#import "Settings.h"

#import "TerminalSettings.h"

@implementation Settings

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if (self != nil) {
    for (int i = 0; i < TERMINAL_COUNT; ++i) {
      NSString* key = [NSString stringWithFormat:@"terminal%d", i];    
      if ([decoder containsValueForKey:key]) {
        terminalSettings[i] = [decoder decodeObjectForKey:key];
      } else {
        terminalSettings[i] = [[TerminalSettings alloc] init];
      }
    }
  }
  return self;
}

- (void) dealloc
{
  for (int i = 0; i < TERMINAL_COUNT; ++i) {
    [terminalSettings[i] release];
  }
  [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  for (int i = 0; i < TERMINAL_COUNT; ++i) {
    NSString* key = [NSString stringWithFormat:@"terminal%d", i];    
    [encoder encodeObject:terminalSettings[i] forKey:key];
  }
}

@end
