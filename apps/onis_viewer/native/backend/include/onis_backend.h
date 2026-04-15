#ifndef ONIS_BACKEND_H_
#define ONIS_BACKEND_H_

#include <stdint.h>

#if defined(_WIN32)
#define ONIS_BACKEND_EXPORT __declspec(dllexport)
#else
#define ONIS_BACKEND_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct OnisBackendHandle OnisBackendHandle;

typedef enum OnisBackendStatus {
  ONIS_BACKEND_OK = 0,
  ONIS_BACKEND_ERROR = 1,
  ONIS_BACKEND_INVALID_ARGUMENT = 2,
} OnisBackendStatus;

ONIS_BACKEND_EXPORT int32_t onis_backend_version(void);

ONIS_BACKEND_EXPORT OnisBackendHandle* onis_backend_create(void);

ONIS_BACKEND_EXPORT void onis_backend_destroy(OnisBackendHandle* handle);

ONIS_BACKEND_EXPORT OnisBackendStatus
onis_backend_ping(OnisBackendHandle* handle, int32_t value, int32_t* out_value);

ONIS_BACKEND_EXPORT int32_t onis_backend_instance_id(OnisBackendHandle* handle);

ONIS_BACKEND_EXPORT const char* onis_backend_get_last_error(void);

#ifdef __cplusplus
}
#endif

#endif  // ONIS_BACKEND_H_
