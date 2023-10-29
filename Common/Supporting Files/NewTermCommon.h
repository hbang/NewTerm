//
//  NewTermCommon.h
//  NewTerm
//
//  Created by Adam Demasi on 20/6/19.
//

#import <TargetConditionals.h>
#import <spawn.h>
#import <pwd.h>

#if TARGET_OS_MACCATALYST || TARGET_OS_SIMULATOR
static inline int ie_getpwuid_r(uid_t uid, struct passwd *pw, char *buf, size_t buflen, struct passwd **pwretp) {
	return getpwuid_r(uid, pw, buf, buflen, pwretp);
}

static inline int ie_posix_spawn(pid_t *pid, const char *path, const posix_spawn_file_actions_t *file_actions, const posix_spawnattr_t *attrp, char *const argv[], char *const envp[]) {
	return posix_spawn(pid, path, file_actions, attrp, argv, envp);
}
#else
extern int ie_getpwuid_r(uid_t uid, struct passwd *pw, char *buf, size_t buflen, struct passwd **pwretp);
extern int ie_posix_spawn(pid_t *pid, const char *path, const posix_spawn_file_actions_t *file_actions, const posix_spawnattr_t *attrp, char *const argv[], char *const envp[]);

#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE ((uint32_t) 1)

// https://github.com/apple-oss-distributions/xnu/blob/1031c584a5e37aff177559b9f69dbd3c8c3fd30a/libsyscall/wrappers/spawn/spawn_private.h#L87-L89
extern int posix_spawnattr_set_persona_np(const posix_spawnattr_t *attr, uid_t persona_id, uint32_t flags);
extern int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t *attr, uid_t uid);
extern int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t *attr, gid_t gid);
#endif
