// SubProcess.m
// MobileTerminal

#import "SubProcess.h"

#include <util.h>
#include <sys/ttycom.h>
#include <sys/stat.h>
#include <unistd.h>

// These are simply used to initialize the terminal and are probably thrown
// away immediately after startup.
static const int kDefaultWidth = 80;
static const int kDefaultHeight = 25;

// Default username if we can't tell from the environment
static const char kDefaultUsername[] = "mobile";

#define STAT_SIZE sizeof(struct stat)

// This is a workaround for the fact that stat is broken in some of the
// iphone simulator SDKs.  Essentially, calling stat() as is will smash the
// stack so we allocate some additional space for writing scratch data.  This
// likely means that some of the values returned in the stat structure are
// incorrect.
// See http://openradar.appspot.com/8140890 for a full bug report.
static int stat_hack(const char* path, struct stat* st) {
  char buf[STAT_SIZE * 2];
  int retval = stat(path, (struct stat*)buf);
  if (retval == 0) {
    memcpy(st, buf, sizeof(struct stat));
  }
  return retval;
}

static int start_process(const char *path,
                         char *const args[],
                         char *const env[])
{
  struct stat st;
  bzero(&st, sizeof(struct stat));
  if (stat_hack(path, &st) != 0) {
    fprintf(stderr, "%s: File does not exist\n", path);
    return -1;
  }
  // Notably, we don't test group or other bits so this still might not always
  // notice if the binary is not executable by us.
  if ((st.st_mode & S_IXUSR) == 0) {
    fprintf(stderr, "%s: Permission denied\n", path);
    return -1;
  }
  if (execve(path, args, env) == -1) {
    perror("execlp:");
    return -1;
  }
  // execve never returns if successful
  return 0;
}

@implementation SubProcess

- (id) init
{
  self = [super init];
  if (self != nil) {
    child_pid = 0;
    fd = 0;
    fileHandle = nil;
  }
  return self;
}

- (void) dealloc
{
  if (child_pid != 0) {
    [NSException raise:@"IllegalStateException"
                format:@"SubProcess was deallocated while running"];
  }
  [super dealloc];
}

- (void)start
{
  if (child_pid != 0) {
    [NSException raise:@"IllegalStateException"
                format:@"SubProcess was already started"];
    return;
  }

  const char* username = getenv("USER");
  if (username == NULL) {
    username = kDefaultUsername;
  }
  
  struct winsize window_size;
  window_size.ws_col = kDefaultWidth;
  window_size.ws_row = kDefaultHeight;
  pid_t pid = forkpty(&fd, NULL, NULL, &window_size);
  if (pid == -1) {
    if (errno == EPERM) {
      [NSException raise:@"ForkException"
                  format:@"Not allowed to fork from inside Sandbox"];
    } else {
      [NSException raise:@"ForkException"
                  format:@"Failed to fork child process (%d: %s)", errno,
                          strerror(errno)];
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
    child_pid = pid;
    // We're the parent process (still).
    fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:fd
                                               closeOnDealloc:YES];
  }
}

- (void)stop
{
  if (child_pid == 0) {
    [NSException raise:@"IllegalStateException"
                format:@"SubProcess was never started"];
    return;
  }
  
  kill(child_pid, SIGHUP);
  int stat;
  waitpid(child_pid, &stat, WUNTRACED);

  fd = 0;
  child_pid = 0;
  [fileHandle release];
}

- (NSFileHandle*)fileHandle {
  return fileHandle;
}

@end
