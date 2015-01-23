// SubProcess.h
// MobileTerminal

#import <Foundation/Foundation.h>
#import "HBNTPTY.h"

// Forks a terminal subprocess.
@interface HBNTSubProcess : NSObject

// Forks a terminal subprocess and initializes the fileHandle for communication.
- (void)start;

// Kills the forked subprocess, blocking until it ends.
- (void)stop;

// Communication channel with the terminal subprocess.	Only valid after the
// sub process is started.
@property (strong, nonatomic, readonly) NSFileHandle *fileHandle;

@end
