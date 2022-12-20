//
//  NewTermCommon.h
//  NewTerm
//
//  Created by Adam Demasi on 20/6/19.
//

#import <TargetConditionals.h>
#import <spawn.h>
#import <pwd.h>

#if TARGET_OS_MACCATALYST
static inline int ie_getpwuid_r(uid_t uid, struct passwd *pw, char *buf, size_t buflen, struct passwd **pwretp) {
	return getpwuid_r(uid, pw, buf, buflen, pwretp);
}

static inline int ie_posix_spawn(pid_t *pid, const char *path, const posix_spawn_file_actions_t *file_actions, const posix_spawnattr_t *attrp, char *const argv[], char *const envp[]) {
	return posix_spawn(pid, path, file_actions, attrp, argv, envp);
}
#else
extern int ie_getpwuid_r(uid_t uid, struct passwd *pw, char *buf, size_t buflen, struct passwd **pwretp);
extern int ie_posix_spawn(pid_t *pid, const char *path, const posix_spawn_file_actions_t *file_actions, const posix_spawnattr_t *attrp, char *const argv[], char *const envp[]);
#endif
