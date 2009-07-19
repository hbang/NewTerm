// SubProcess.h
// MobileTerminal

#import <Foundation/Foundation.h>
#import "PTY.h"

// Forks a terminal subprocess.
@interface SubProcess : NSObject {
@private
  pid_t child_pid;
  int fd;
  NSFileHandle* fileHandle;
}

- (id)init;
- (void)dealloc;

// Forks a terminal subprocess and initializes the fileHandle for communication.
- (void)start;

// Kills the forked subprocess, blocking until it ends.
- (void)stop;

// Communication channel with the terminal subprocess.  Only valid after the
// sub process is started.
- (NSFileHandle*)fileHandle;

@end
