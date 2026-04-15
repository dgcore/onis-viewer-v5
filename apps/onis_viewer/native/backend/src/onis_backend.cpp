#include "onis_backend.h"

#include <atomic>
#include <mutex>
#include <string>

struct OnisBackendHandle {
  int32_t generation;
};

namespace {
std::string g_last_error;
std::atomic<int32_t> g_generation{0};
std::atomic<int32_t> g_ref_count{0};
std::mutex g_backend_mutex;
OnisBackendHandle* g_shared_backend = nullptr;

void set_last_error(const char* message) { g_last_error = message; }
}  // namespace

int32_t onis_backend_version(void) { return 1; }

OnisBackendHandle* onis_backend_create(void) {
  std::lock_guard<std::mutex> lock(g_backend_mutex);
  if (g_shared_backend == nullptr) {
    g_shared_backend = new OnisBackendHandle();
    g_shared_backend->generation = ++g_generation;
  }
  ++g_ref_count;
  return g_shared_backend;
}

void onis_backend_destroy(OnisBackendHandle* handle) {
  std::lock_guard<std::mutex> lock(g_backend_mutex);
  if (handle == nullptr || g_shared_backend == nullptr) {
    return;
  }
  if (handle != g_shared_backend) {
    set_last_error("Invalid argument: handle does not match shared backend.");
    return;
  }

  const int32_t next_count = --g_ref_count;
  if (next_count <= 0) {
    delete g_shared_backend;
    g_shared_backend = nullptr;
    g_ref_count = 0;
  }
}

OnisBackendStatus onis_backend_ping(OnisBackendHandle* handle,
                                    int32_t value,
                                    int32_t* out_value) {
  if (handle == nullptr || out_value == nullptr) {
    set_last_error("Invalid argument: handle or out_value is null.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  // Keep this deterministic for smoke-testing FFI call integrity.
  *out_value = value + handle->generation;
  return ONIS_BACKEND_OK;
}

int32_t onis_backend_instance_id(OnisBackendHandle* handle) {
  if (handle == nullptr) {
    set_last_error("Invalid argument: handle is null.");
    return -1;
  }
  return handle->generation;
}

const char* onis_backend_get_last_error(void) { return g_last_error.c_str(); }
