// SubProcess.m
// MobileTerminal

#import "HBNTSubProcess.h"

#include <util.h>
#include <sys/ttycom.h>
#include <unistd.h>

// These are simply used to initialize the terminal and are probably thrown
// away immediately after startup.
static const int kDefaultWidth = 80;
static const int kDefaultHeight = 25;

// Default username if we can't tell from the environment
static const char kDefaultUsername[] = "mobile";

@implementation HBNTSubProcess {
	pid_t _childPID;
	int _fileDescriptor;
}

- (void)dealloc {
	if (_childPID != 0) {
		[NSException raise:@"IllegalStateException" format:@"SubProcess was deallocated while running"];
	}
}

#pragma mark - Start/stop

- (void)start {
	if (_childPID != 0) {
		[NSException raise:@"IllegalStateException" format:@"SubProcess was already started"];
		return;
	}

	const char *username = getenv("USER");

	if (username == NULL) {
		username = kDefaultUsername;
	}

	struct winsize window_size;
	window_size.ws_col = kDefaultWidth;
	window_size.ws_row = kDefaultHeight;
	pid_t pid = forkpty(&_fileDescriptor, NULL, NULL, &window_size);

	if (pid == -1) {
		if (errno == EPERM) {
			[NSException raise:@"ForkException" format:@"Not allowed to fork from inside Sandbox"];
		} else {
			[NSException raise:@"ForkException" format:@"Failed to fork child process (%d: %s)", errno, strerror(errno)];
		}
	} else if (pid == 0) {
		// Handle the child subprocess
		// First try to use /bin/login since its a little nicer. Fall back to
		// /bin/sh if that is available.
		char *login_args[] = { "login", "-fp", (char *)username, NULL };
		char *sh_args[] = { "sh", NULL };

		// TODO: these should be configurable
		char *env[] = {
			"TERM=xterm-color",
			"LANG=en_US.UTF-8",
			NULL
		};

		// NOTE: These should never return if successful
		[self _startProcess:@"/usr/bin/login" arguments:login_args environment:env];
		[self _startProcess:@"/bin/login" arguments:login_args environment:env];
		[self _startProcess:@"/bin/sh" arguments:sh_args environment:env];
		[self _startProcess:@"/bootstrap/bin/bash" arguments:sh_args environment:env];
	} else {
		HBLogDebug(@"process forked: %d", pid);
		_childPID = pid;

		// We're the parent process (still).
		_fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:_fileDescriptor closeOnDealloc:YES];
	}
}

- (void)stop {
	if (_childPID == 0) {
		[NSException raise:@"IllegalStateException" format:@"SubProcess was never started"];
		return;
	}

	kill(_childPID, SIGKILL);
	int stat;
	waitpid(_childPID, &stat, WUNTRACED);

	_fileDescriptor = 0;
	_childPID = 0;
}

- (int)_startProcess:(NSString *)path arguments:(char *const[])args environment:(char *const[])env {
	NSFileManager *fileManager = [NSFileManager defaultManager];

	if (![fileManager fileExistsAtPath:path]) {
		return -1;
	}

	// Notably, we don't test group or other bits so this still might not always
	// notice if the binary is not executable by us.
	if (![fileManager isExecutableFileAtPath:path]) {
		return -1;
	}

	if (execve(path.UTF8String, args, env) == -1) {
		HBLogError(@"%@: exec failed: %s", path, strerror(errno));
		return -1;
	}

	// execve never returns if successful
	return 0;
}

@end
