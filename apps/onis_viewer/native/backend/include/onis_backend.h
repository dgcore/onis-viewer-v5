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

/// Mirrors `onis::frame_region` / viewer [ImageRegion] for FFI.
typedef struct OnisBackendDicomRegion {
  int32_t spatial_format;
  int32_t data_type;
  double original_spacing_x;
  double original_spacing_y;
  int32_t original_unit_x;
  int32_t original_unit_y;
  double calibrated_spacing_x;
  double calibrated_spacing_y;
  int32_t calibrated_unit_x;
  int32_t calibrated_unit_y;
  int32_t x0;
  int32_t x1;
  int32_t y0;
  int32_t y1;
} OnisBackendDicomRegion;

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

/// Load a DICOM Part 10 file from disk (UTF-8 path). Returns a stable id for
/// this session.
ONIS_BACKEND_EXPORT OnisBackendStatus onis_backend_dicom_load_file(
    OnisBackendHandle* handle, const char* utf8_path, int32_t* out_id);

/// Release a DICOM instance previously returned by
/// onis_backend_dicom_load_file.
ONIS_BACKEND_EXPORT OnisBackendStatus
onis_backend_dicom_release(OnisBackendHandle* handle, int32_t id);

/// Read one attribute as UTF-8 text (same path as internal
/// `get_string_element`). [tag_key] is `(group << 16) | element` (e.g.
/// 0x00080018 for SOP Instance UID). [vr_utf8] is the DICOM VR ASCII, e.g.
/// "UI", "CS", "DS" (required by DCMTK read). On success writes a
/// NUL-terminated string into [out_buf] if it fits. If the tag is missing or
/// empty, writes "" and returns ONIS_BACKEND_OK.
ONIS_BACKEND_EXPORT OnisBackendStatus onis_backend_dicom_get_string_element(
    OnisBackendHandle* handle, int32_t dicom_id, uint32_t tag_key,
    const char* vr_utf8, char* out_buf, uint32_t out_buf_size,
    uint32_t* out_written);

/// Copies up to [max_regions] entries from [dicom_dcmtk_base::get_regions].
/// On success, [out_count] is the total number of regions (may exceed
/// [max_regions]).
ONIS_BACKEND_EXPORT OnisBackendStatus
onis_backend_dicom_get_regions(OnisBackendHandle* handle, int32_t dicom_id,
                               OnisBackendDicomRegion* out_regions,
                               int32_t max_regions, int32_t* out_count);

/// Builds a native [onis::dicom_frame] via [onis::dicom_file::extract_frame].
/// The returned [out_frame_id] must be released with
/// [onis_backend_dicom_frame_release]. Releasing the parent [dicom_id] also
/// drops all frames created from that dataset.
ONIS_BACKEND_EXPORT OnisBackendStatus
onis_backend_dicom_frame_create(OnisBackendHandle* handle, int32_t dicom_id,
                                int32_t frame_index, int32_t* out_frame_id);

ONIS_BACKEND_EXPORT OnisBackendStatus
onis_backend_dicom_frame_release(OnisBackendHandle* handle, int32_t frame_id);

/// Retrieves the pixel dimensions of a frame.
ONIS_BACKEND_EXPORT OnisBackendStatus onis_backend_dicom_frame_get_dimensions(
    OnisBackendHandle* handle, int32_t frame_id, int32_t* out_width,
    int32_t* out_height);

/// [out_is_monochrome]: 0 = false, 1 = true (`dicom_frame::is_monochrome`).
ONIS_BACKEND_EXPORT OnisBackendStatus onis_backend_dicom_frame_is_monochrome(
    OnisBackendHandle* handle, int32_t frame_id, int32_t* out_is_monochrome);

/// Bits per pixel from `dicom_frame::get_bits_per_pixel` (planes * depth).
ONIS_BACKEND_EXPORT OnisBackendStatus
onis_backend_dicom_frame_get_bits_per_pixel(OnisBackendHandle* handle,
                                            int32_t frame_id,
                                            int32_t* out_bits);

/// Query or copy `dicom_frame::get_intermediate_pixel_data`.
/// If [out_buf] is NULL, writes the required byte count to [out_written] only.
/// If [out_buf] is non-NULL, [out_buf_size] must be >= that count; copies all
/// bytes.
ONIS_BACKEND_EXPORT OnisBackendStatus
onis_backend_dicom_frame_get_intermediate_pixel_data(OnisBackendHandle* handle,
                                                     int32_t frame_id,
                                                     uint8_t* out_buf,
                                                     uint32_t out_buf_size,
                                                     uint32_t* out_written);

/// `dicom_frame::get_representation` — [out_bits] is 8 / 16 / 32, or 0 if
/// unknown. [out_is_signed]: 0 = unsigned, 1 = signed.
ONIS_BACKEND_EXPORT OnisBackendStatus
onis_backend_dicom_frame_get_representation(OnisBackendHandle* handle,
                                            int32_t frame_id, int32_t* out_bits,
                                            int32_t* out_is_signed);

/// [intermediate]: 0 = display-scaled min/max, 1 = stored intermediate min/max
/// (`dicom_frame::get_min_max_values`).
ONIS_BACKEND_EXPORT OnisBackendStatus
onis_backend_dicom_frame_get_min_max_values(OnisBackendHandle* handle,
                                            int32_t frame_id,
                                            int32_t intermediate,
                                            double* out_min, double* out_max);

/// `dicom_frame::get_rescale_and_intercept`.
ONIS_BACKEND_EXPORT OnisBackendStatus
onis_backend_dicom_frame_get_rescale_intercept(OnisBackendHandle* handle,
                                               int32_t frame_id,
                                               double* out_rescale,
                                               double* out_intercept);

/// Copies one channel (0=R, 1=G, 2=B) from [dicom_frame::get_palette] into
/// [out_buf]. If [out_buf] is NULL, writes the required byte count to
/// [out_written] only. If the channel has no palette data, sets [out_count]=0,
/// [out_bits]=0, [out_written]=0. When [out_first_mapped] is non-NULL, writes
/// the first mapped value from the dataset descriptor (0028,1101–1103) or 0.
ONIS_BACKEND_EXPORT OnisBackendStatus onis_backend_dicom_frame_copy_palette(
    OnisBackendHandle* handle, int32_t frame_id, int32_t channel,
    int32_t* out_count, int32_t* out_bits, int32_t* out_first_mapped,
    uint8_t* out_buf, uint32_t out_buf_size, uint32_t* out_written);

#ifdef __cplusplus
}
#endif

#endif  // ONIS_BACKEND_H_
