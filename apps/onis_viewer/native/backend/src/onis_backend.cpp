#include "onis_backend.h"

#include "dicom_dcmtk.hpp"

#include <atomic>
#include <map>
#include <memory>
#include <mutex>
#include <string>

extern void dcmtk_init();

struct OnisBackendHandle {
  int32_t generation = 0;
  onis::dicom_manager_ptr dicom_manager;
  std::map<int32_t, onis::dicom_file_ptr> dicoms;
  int32_t next_dicom_id = 1;
};

namespace {
std::string g_last_error;
std::atomic<int32_t> g_generation{0};
std::atomic<int32_t> g_ref_count{0};
std::mutex g_backend_mutex;
OnisBackendHandle* g_shared_backend = nullptr;
std::once_flag g_dcmtk_init_once;

void set_last_error(const char* message) { g_last_error = message; }

void ensure_dcmtk_initialized() {
  std::call_once(g_dcmtk_init_once, [] { dcmtk_init(); });
}
}  // namespace

int32_t onis_backend_version(void) { return 2; }

OnisBackendHandle* onis_backend_create(void) {
  std::lock_guard<std::mutex> lock(g_backend_mutex);
  if (g_shared_backend == nullptr) {
    ensure_dcmtk_initialized();
    g_shared_backend = new OnisBackendHandle();
    g_shared_backend->generation = ++g_generation;
    g_shared_backend->dicom_manager = dicom_dcmtk_manager::create();
    if (!g_shared_backend->dicom_manager) {
      delete g_shared_backend;
      g_shared_backend = nullptr;
      set_last_error("Failed to create DICOM manager.");
      return nullptr;
    }
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
    g_shared_backend->dicoms.clear();
    g_shared_backend->dicom_manager.reset();
    delete g_shared_backend;
    g_shared_backend = nullptr;
    g_ref_count = 0;
  }
}

OnisBackendStatus onis_backend_ping(OnisBackendHandle* handle, int32_t value,
                                    int32_t* out_value) {
  if (handle == nullptr || out_value == nullptr) {
    set_last_error("Invalid argument: handle or out_value is null.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

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

OnisBackendStatus onis_backend_dicom_load_file(OnisBackendHandle* handle,
                                               const char* utf8_path,
                                               int32_t* out_id) {
  if (handle == nullptr || utf8_path == nullptr || out_id == nullptr) {
    set_last_error(
        "Invalid argument: handle, utf8_path, or out_id is null.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  std::lock_guard<std::mutex> lock(g_backend_mutex);
  if (g_shared_backend == nullptr || handle != g_shared_backend) {
    set_last_error("Invalid argument: backend handle is not active.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }
  if (!g_shared_backend->dicom_manager) {
    set_last_error("DICOM manager not initialized.");
    return ONIS_BACKEND_ERROR;
  }

  onis::dicom_file_ptr dcm =
      g_shared_backend->dicom_manager->create_dicom_file();
  if (!dcm) {
    set_last_error("Failed to create DICOM file object.");
    return ONIS_BACKEND_ERROR;
  }

  if (!dcm->load_file(std::string(utf8_path))) {
    set_last_error("Failed to load DICOM file.");
    return ONIS_BACKEND_ERROR;
  }

  const int32_t id = g_shared_backend->next_dicom_id++;
  g_shared_backend->dicoms[id] = std::move(dcm);
  *out_id = id;
  return ONIS_BACKEND_OK;
}

OnisBackendStatus onis_backend_dicom_release(OnisBackendHandle* handle,
                                             int32_t id) {
  if (handle == nullptr) {
    set_last_error("Invalid argument: handle is null.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  std::lock_guard<std::mutex> lock(g_backend_mutex);
  if (g_shared_backend == nullptr || handle != g_shared_backend) {
    set_last_error("Invalid argument: backend handle is not active.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  const auto it = g_shared_backend->dicoms.find(id);
  if (it == g_shared_backend->dicoms.end()) {
    set_last_error("Unknown DICOM id.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }
  g_shared_backend->dicoms.erase(it);
  return ONIS_BACKEND_OK;
}
