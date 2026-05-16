#include "onis_backend.h"

#include "dicom_dcmtk.hpp"
#include "onis_kit/include/core/exception.hpp"

#include <algorithm>
#include <atomic>
#include <cstdint>
#include <cstring>
#include <map>
#include <memory>
#include <mutex>
#include <string>

extern void dcmtk_init();

struct OnisBackendDicomFrameSlot {
  onis::dicom_frame_ptr frame;
  int32_t dicom_id = 0;
};

struct OnisBackendHandle {
  int32_t generation = 0;
  onis::dicom_manager_ptr dicom_manager;
  std::map<int32_t, onis::dicom_file_ptr> dicoms;
  int32_t next_dicom_id = 1;
  std::map<int32_t, OnisBackendDicomFrameSlot> dicom_frames;
  int32_t next_frame_id = 1;
};

namespace {
std::string g_last_error;
std::atomic<int32_t> g_generation{0};
std::atomic<int32_t> g_ref_count{0};
std::mutex g_backend_mutex;
OnisBackendHandle* g_shared_backend = nullptr;
std::once_flag g_dcmtk_init_once;

void set_last_error(const char* message) {
  g_last_error = message;
}

void ensure_dcmtk_initialized() {
  std::call_once(g_dcmtk_init_once, [] { dcmtk_init(); });
}

void erase_dicom_frames_for_dataset(OnisBackendHandle* handle,
                                    int32_t dicom_id) {
  for (auto it = handle->dicom_frames.begin();
       it != handle->dicom_frames.end();) {
    if (it->second.dicom_id == dicom_id) {
      it = handle->dicom_frames.erase(it);
    } else {
      ++it;
    }
  }
}

std::int32_t parse_palette_descriptor_first_mapped(
    const std::string& descriptor) {
  const auto p0 = descriptor.find('\\');
  if (p0 == std::string::npos) {
    return 0;
  }
  const auto p1 = descriptor.find('\\', p0 + 1);
  const std::string token = p1 == std::string::npos
                                ? descriptor.substr(p0 + 1)
                                : descriptor.substr(p0 + 1, p1 - p0 - 1);
  try {
    return static_cast<std::int32_t>(std::stol(token));
  } catch (...) {
    return 0;
  }
}

static std::int32_t palette_descriptor_tag(std::int32_t channel) {
  return static_cast<std::int32_t>(0x00281101 + channel);
}
}  // namespace

int32_t onis_backend_version(void) {
  return 10;
}

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
    g_shared_backend->dicom_frames.clear();
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

const char* onis_backend_get_last_error(void) {
  return g_last_error.c_str();
}

OnisBackendStatus onis_backend_dicom_load_file(OnisBackendHandle* handle,
                                               const char* utf8_path,
                                               int32_t* out_id) {
  if (handle == nullptr || utf8_path == nullptr || out_id == nullptr) {
    set_last_error("Invalid argument: handle, utf8_path, or out_id is null.");
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
  erase_dicom_frames_for_dataset(g_shared_backend, id);
  g_shared_backend->dicoms.erase(it);
  return ONIS_BACKEND_OK;
}

OnisBackendStatus onis_backend_dicom_get_string_element(
    OnisBackendHandle* handle, int32_t dicom_id, uint32_t tag_key,
    const char* vr_utf8, char* out_buf, uint32_t out_buf_size,
    uint32_t* out_written) {
  if (handle == nullptr || vr_utf8 == nullptr || out_buf == nullptr ||
      out_buf_size == 0 || out_written == nullptr) {
    set_last_error(
        "Invalid argument: handle, vr_utf8, out_buf, or out_written is null.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  std::lock_guard<std::mutex> lock(g_backend_mutex);
  if (g_shared_backend == nullptr || handle != g_shared_backend) {
    set_last_error("Invalid argument: backend handle is not active.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  const auto it = g_shared_backend->dicoms.find(dicom_id);
  if (it == g_shared_backend->dicoms.end()) {
    set_last_error("Unknown DICOM id.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  std::string val;
  const bool ok = it->second->get_string_element(
      val, static_cast<std::int32_t>(tag_key), std::string(vr_utf8));
  if (!ok) {
    out_buf[0] = '\0';
    *out_written = 0;
    return ONIS_BACKEND_OK;
  }

  const std::size_t n = val.size();
  if (n + 1 > static_cast<std::size_t>(out_buf_size)) {
    set_last_error("Output buffer too small for DICOM string element.");
    return ONIS_BACKEND_ERROR;
  }
  std::memcpy(out_buf, val.data(), n);
  out_buf[n] = '\0';
  *out_written = static_cast<uint32_t>(n);
  return ONIS_BACKEND_OK;
}

OnisBackendStatus onis_backend_dicom_get_regions(
    OnisBackendHandle* handle, int32_t dicom_id,
    OnisBackendDicomRegion* out_regions, int32_t max_regions,
    int32_t* out_count) {
  if (handle == nullptr || out_count == nullptr) {
    set_last_error("Invalid argument: handle or out_count is null.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }
  if (max_regions > 0 && out_regions == nullptr) {
    set_last_error(
        "Invalid argument: out_regions is null but max_regions > 0.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }
  if (max_regions < 0) {
    set_last_error("Invalid argument: max_regions is negative.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  std::lock_guard<std::mutex> lock(g_backend_mutex);
  if (g_shared_backend == nullptr || handle != g_shared_backend) {
    set_last_error("Invalid argument: backend handle is not active.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  const auto it = g_shared_backend->dicoms.find(dicom_id);
  if (it == g_shared_backend->dicoms.end()) {
    set_last_error("Unknown DICOM id.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  onis::frame_region_list list;
  it->second->get_regions(list);
  const int32_t n = static_cast<int32_t>(list.size());
  *out_count = n;

  const int32_t copy = std::min(n, max_regions);
  for (int32_t i = 0; i < copy; ++i) {
    const onis::frame_region_ptr& r = list[static_cast<size_t>(i)];
    OnisBackendDicomRegion& o = out_regions[i];
    o.spatial_format = r->spatial_format;
    o.data_type = r->data_type;
    o.original_spacing_x = r->original_spacing[0];
    o.original_spacing_y = r->original_spacing[1];
    o.original_unit_x = r->original_unit[0];
    o.original_unit_y = r->original_unit[1];
    o.calibrated_spacing_x = r->calibrated_spacing[0];
    o.calibrated_spacing_y = r->calibrated_spacing[1];
    o.calibrated_unit_x = r->calibrated_unit[0];
    o.calibrated_unit_y = r->calibrated_unit[1];
    o.x0 = r->x0;
    o.x1 = r->x1;
    o.y0 = r->y0;
    o.y1 = r->y1;
  }
  return ONIS_BACKEND_OK;
}

OnisBackendStatus onis_backend_dicom_frame_create(OnisBackendHandle* handle,
                                                  int32_t dicom_id,
                                                  int32_t frame_index,
                                                  int32_t* out_frame_id) {
  if (handle == nullptr || out_frame_id == nullptr) {
    set_last_error("Invalid argument: handle or out_frame_id is null.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  std::lock_guard<std::mutex> lock(g_backend_mutex);
  if (g_shared_backend == nullptr || handle != g_shared_backend) {
    set_last_error("Invalid argument: backend handle is not active.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  const auto it = g_shared_backend->dicoms.find(dicom_id);
  if (it == g_shared_backend->dicoms.end()) {
    set_last_error("Unknown DICOM id.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  onis::dicom_frame_ptr frame;
  try {
    frame = it->second->extract_frame(frame_index);
  } catch (const onis::exception& ex) {
    std::string msg = "extract_frame error code=";
    msg += std::to_string(ex.get_code());
    if (ex.what()[0] != '\0') {
      msg += " msg=";
      msg += ex.what();
    }
    set_last_error(msg.c_str());
    return ONIS_BACKEND_ERROR;
  } catch (const std::exception& ex) {
    std::string msg = "extract_frame std::exception: ";
    msg += ex.what();
    set_last_error(msg.c_str());
    return ONIS_BACKEND_ERROR;
  } catch (...) {
    set_last_error("extract_frame threw unknown exception.");
    return ONIS_BACKEND_ERROR;
  }

  if (!frame) {
    set_last_error("extract_frame returned null.");
    return ONIS_BACKEND_ERROR;
  }

  const int32_t fid = g_shared_backend->next_frame_id++;
  OnisBackendDicomFrameSlot slot;
  slot.frame = std::move(frame);
  slot.dicom_id = dicom_id;
  g_shared_backend->dicom_frames[fid] = std::move(slot);
  *out_frame_id = fid;
  return ONIS_BACKEND_OK;
}

OnisBackendStatus onis_backend_dicom_frame_release(OnisBackendHandle* handle,
                                                   int32_t frame_id) {
  if (handle == nullptr) {
    set_last_error("Invalid argument: handle is null.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  std::lock_guard<std::mutex> lock(g_backend_mutex);
  if (g_shared_backend == nullptr || handle != g_shared_backend) {
    set_last_error("Invalid argument: backend handle is not active.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  const auto it = g_shared_backend->dicom_frames.find(frame_id);
  if (it == g_shared_backend->dicom_frames.end()) {
    return ONIS_BACKEND_OK;
  }
  g_shared_backend->dicom_frames.erase(it);
  return ONIS_BACKEND_OK;
}

OnisBackendStatus onis_backend_dicom_frame_get_dimensions(
    OnisBackendHandle* handle, int32_t frame_id, int32_t* out_width,
    int32_t* out_height) {
  if (handle == nullptr || out_width == nullptr || out_height == nullptr) {
    set_last_error(
        "Invalid argument: handle, out_width, or out_height is null.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  std::lock_guard<std::mutex> lock(g_backend_mutex);
  if (g_shared_backend == nullptr || handle != g_shared_backend) {
    set_last_error("Invalid argument: backend handle is not active.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  const auto it = g_shared_backend->dicom_frames.find(frame_id);
  if (it == g_shared_backend->dicom_frames.end()) {
    set_last_error("Unknown frame id.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  std::size_t w = 0, h = 0;
  if (!it->second.frame->get_dimensions(&w, &h)) {
    set_last_error("get_dimensions failed.");
    return ONIS_BACKEND_ERROR;
  }
  *out_width = static_cast<int32_t>(w);
  *out_height = static_cast<int32_t>(h);
  return ONIS_BACKEND_OK;
}

OnisBackendStatus onis_backend_dicom_frame_is_monochrome(
    OnisBackendHandle* handle, int32_t frame_id, int32_t* out_is_monochrome) {
  if (handle == nullptr || out_is_monochrome == nullptr) {
    set_last_error("Invalid argument: handle or out_is_monochrome is null.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  std::lock_guard<std::mutex> lock(g_backend_mutex);
  if (g_shared_backend == nullptr || handle != g_shared_backend) {
    set_last_error("Invalid argument: backend handle is not active.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  const auto it = g_shared_backend->dicom_frames.find(frame_id);
  if (it == g_shared_backend->dicom_frames.end()) {
    set_last_error("Unknown frame id.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  *out_is_monochrome = it->second.frame->is_monochrome() ? 1 : 0;
  return ONIS_BACKEND_OK;
}

OnisBackendStatus onis_backend_dicom_frame_get_bits_per_pixel(
    OnisBackendHandle* handle, int32_t frame_id, int32_t* out_bits) {
  if (handle == nullptr || out_bits == nullptr) {
    set_last_error("Invalid argument: handle or out_bits is null.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  std::lock_guard<std::mutex> lock(g_backend_mutex);
  if (g_shared_backend == nullptr || handle != g_shared_backend) {
    set_last_error("Invalid argument: backend handle is not active.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  const auto it = g_shared_backend->dicom_frames.find(frame_id);
  if (it == g_shared_backend->dicom_frames.end()) {
    set_last_error("Unknown frame id.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  *out_bits = it->second.frame->get_bits_per_pixel();
  return ONIS_BACKEND_OK;
}

OnisBackendStatus onis_backend_dicom_frame_get_intermediate_pixel_data(
    OnisBackendHandle* handle, int32_t frame_id, uint8_t* out_buf,
    uint32_t out_buf_size, uint32_t* out_written) {
  if (handle == nullptr || out_written == nullptr) {
    set_last_error("Invalid argument: handle or out_written is null.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  std::lock_guard<std::mutex> lock(g_backend_mutex);
  if (g_shared_backend == nullptr || handle != g_shared_backend) {
    set_last_error("Invalid argument: backend handle is not active.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  const auto it = g_shared_backend->dicom_frames.find(frame_id);
  if (it == g_shared_backend->dicom_frames.end()) {
    set_last_error("Unknown frame id.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  std::size_t cnt = 0;
  const void* ptr = it->second.frame->get_intermediate_pixel_data(&cnt);
  if (ptr == nullptr || cnt == 0) {
    set_last_error("No intermediate pixel data.");
    return ONIS_BACKEND_ERROR;
  }
  if (cnt > static_cast<std::size_t>(UINT32_MAX)) {
    set_last_error("Intermediate pixel data too large.");
    return ONIS_BACKEND_ERROR;
  }
  const uint32_t ucnt = static_cast<uint32_t>(cnt);

  if (out_buf == nullptr) {
    *out_written = ucnt;
    return ONIS_BACKEND_OK;
  }

  if (out_buf_size < ucnt) {
    set_last_error("Output buffer too small for intermediate pixel data.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }
  std::memcpy(out_buf, ptr, cnt);
  *out_written = ucnt;
  return ONIS_BACKEND_OK;
}

OnisBackendStatus onis_backend_dicom_frame_get_representation(
    OnisBackendHandle* handle, int32_t frame_id, int32_t* out_bits,
    int32_t* out_is_signed) {
  if (handle == nullptr || out_bits == nullptr || out_is_signed == nullptr) {
    set_last_error(
        "Invalid argument: handle, out_bits, or out_is_signed is null.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  std::lock_guard<std::mutex> lock(g_backend_mutex);
  if (g_shared_backend == nullptr || handle != g_shared_backend) {
    set_last_error("Invalid argument: backend handle is not active.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  const auto it = g_shared_backend->dicom_frames.find(frame_id);
  if (it == g_shared_backend->dicom_frames.end()) {
    set_last_error("Unknown frame id.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  bool signed_data = false;
  const std::int32_t bits = it->second.frame->get_representation(&signed_data);
  *out_bits = bits;
  *out_is_signed = signed_data ? 1 : 0;
  return ONIS_BACKEND_OK;
}

OnisBackendStatus onis_backend_dicom_frame_get_min_max_values(
    OnisBackendHandle* handle, int32_t frame_id, int32_t intermediate,
    double* out_min, double* out_max) {
  if (handle == nullptr || out_min == nullptr || out_max == nullptr) {
    set_last_error("Invalid argument: handle, out_min, or out_max is null.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  std::lock_guard<std::mutex> lock(g_backend_mutex);
  if (g_shared_backend == nullptr || handle != g_shared_backend) {
    set_last_error("Invalid argument: backend handle is not active.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  const auto it = g_shared_backend->dicom_frames.find(frame_id);
  if (it == g_shared_backend->dicom_frames.end()) {
    set_last_error("Unknown frame id.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  double min_v = 0.0;
  double max_v = 0.0;
  if (!it->second.frame->get_min_max_values(&min_v, &max_v,
                                            intermediate != 0)) {
    set_last_error("get_min_max_values unavailable for this frame.");
    return ONIS_BACKEND_ERROR;
  }
  *out_min = min_v;
  *out_max = max_v;
  return ONIS_BACKEND_OK;
}

OnisBackendStatus onis_backend_dicom_frame_get_rescale_intercept(
    OnisBackendHandle* handle, int32_t frame_id, double* out_rescale,
    double* out_intercept) {
  if (handle == nullptr || out_rescale == nullptr || out_intercept == nullptr) {
    set_last_error(
        "Invalid argument: handle, out_rescale, or out_intercept is null.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  std::lock_guard<std::mutex> lock(g_backend_mutex);
  if (g_shared_backend == nullptr || handle != g_shared_backend) {
    set_last_error("Invalid argument: backend handle is not active.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  const auto it = g_shared_backend->dicom_frames.find(frame_id);
  if (it == g_shared_backend->dicom_frames.end()) {
    set_last_error("Unknown frame id.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  double rescale = 1.0;
  double intercept = 0.0;
  if (!it->second.frame->get_rescale_and_intercept(&rescale, &intercept)) {
    set_last_error("get_rescale_and_intercept failed.");
    return ONIS_BACKEND_ERROR;
  }
  *out_rescale = rescale;
  *out_intercept = intercept;
  return ONIS_BACKEND_OK;
}

OnisBackendStatus onis_backend_dicom_frame_copy_palette(
    OnisBackendHandle* handle, int32_t frame_id, int32_t channel,
    int32_t* out_count, int32_t* out_bits, int32_t* out_first_mapped,
    uint8_t* out_buf, uint32_t out_buf_size, uint32_t* out_written) {
  if (handle == nullptr || out_count == nullptr || out_bits == nullptr ||
      out_written == nullptr) {
    set_last_error(
        "Invalid argument: handle, out_count, out_bits, or out_written is "
        "null.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }
  if (channel < 0 || channel > 2) {
    set_last_error("Invalid argument: palette channel must be 0, 1, or 2.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  std::lock_guard<std::mutex> lock(g_backend_mutex);
  if (g_shared_backend == nullptr || handle != g_shared_backend) {
    set_last_error("Invalid argument: backend handle is not active.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  const auto it = g_shared_backend->dicom_frames.find(frame_id);
  if (it == g_shared_backend->dicom_frames.end()) {
    set_last_error("Unknown frame id.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }

  const OnisBackendDicomFrameSlot& slot = it->second;
  onis::dicom_palette* pal = slot.frame->get_palette(channel);

  if (out_first_mapped != nullptr) {
    *out_first_mapped = 0;
    const auto di = g_shared_backend->dicoms.find(slot.dicom_id);
    if (di != g_shared_backend->dicoms.end() && di->second) {
      std::string desc;
      if (di->second->get_string_element(desc, palette_descriptor_tag(channel),
                                         "US")) {
        *out_first_mapped = parse_palette_descriptor_first_mapped(desc);
      }
    }
  }

  const std::size_t nbytes =
      (pal == nullptr || pal->data == nullptr || pal->count <= 0)
          ? 0
          : (pal->bits == 16 ? static_cast<std::size_t>(pal->count) * 2u
                             : static_cast<std::size_t>(pal->count));
  if (nbytes == 0) {
    *out_count = 0;
    *out_bits = 0;
    *out_written = 0;
    return ONIS_BACKEND_OK;
  }
  if (nbytes > static_cast<std::size_t>(UINT32_MAX)) {
    set_last_error("Palette data too large.");
    return ONIS_BACKEND_ERROR;
  }

  *out_count = pal->count;
  *out_bits = pal->bits;
  const uint32_t ucnt = static_cast<uint32_t>(nbytes);

  if (out_buf == nullptr) {
    *out_written = ucnt;
    return ONIS_BACKEND_OK;
  }

  if (out_buf_size < ucnt) {
    set_last_error("Output buffer too small for palette data.");
    return ONIS_BACKEND_INVALID_ARGUMENT;
  }
  std::memcpy(out_buf, pal->data, nbytes);
  *out_written = ucnt;
  return ONIS_BACKEND_OK;
}
