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

static int start_process(const char *path, char *const args[], char *const env[]) {
	NSString *pathString = [NSString stringWithUTF8String:path];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath:pathString]) {
		fprintf(stderr, "%s: File does not exist\n", path);
		return -1;
	}
	// Notably, we don't test group or other bits so this still might not always
	// notice if the binary is not executable by us.
	if (![fileManager isExecutableFileAtPath:pathString]) {
		fprintf(stderr, "%s: File does not exist\n", path);
		return -1;
	}
	if (execve(path, args, env) == -1) {
		perror("execlp:");
		return -1;
	}
	// execve never returns if successful
	return 0;
}

@implementation HBNTSubProcess {
	pid_t _childPID;
	int _fileDescriptor;
}

- (void)dealloc {
	if (_childPID != 0) {
		[NSException raise:@"IllegalStateException" format:@"SubProcess was deallocated while running"];
	}
}

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
		return;
	} else if (pid == 0) {
		// Handle the child subprocess
		// First try to use /bin/login since its a little nicer. Fall back to
		// /bin/sh if that is available.
		char * login_args[] = { "login", "-fp", (char*)username, (char *)0, };
		char * sh_args[] = { "sh", (char *)0, };
		char * env[] = { "TERM=xterm-color", (char *)0 };
		// NOTE: These should never return if successful
		start_process("/usr/bin/login", login_args, env);
		start_process("/bin/login", login_args, env);
		start_process("/bin/sh", sh_args, env);
		return;
	} else {
		NSLog(@"process forked: %d", pid);
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

@end
