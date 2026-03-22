//
//  Pogo-BridgingHeader.h
//  Pogo
//
//  Created by Amy While on 12/09/2022.
//

#ifndef Pogo_BridgingHeader_h
#define Pogo_BridgingHeader_h

#include <spawn.h>
#include <sys/types.h>
#include <stdint.h>

#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1
int posix_spawnattr_set_persona_np(const posix_spawnattr_t *__restrict attr, uid_t uid, uint32_t flags);
int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t *__restrict attr, uid_t uid);
int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t *__restrict attr, uid_t gid);


#endif /* Pogo_BridgingHeader_h */
