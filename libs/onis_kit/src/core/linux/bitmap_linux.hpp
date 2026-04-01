#pragma once

#include <mutex>
#include "../../../include/core/bitmap.hpp"

namespace onis::core {

///////////////////////////////////////////////////////////////////////
// bitmap_linux
///////////////////////////////////////////////////////////////////////

class bitmap_linux : public bitmap {
public:
  bitmap_linux();
  virtual ~bitmap_linux();

  // clone:
  bitmap_ptr clone();

  // internal data:
  void* get_internal_data();
  void set_internal_data(void* data, bool delete_old);

  // Dimension:
  std::size_t get_width();
  std::size_t get_height();

  // pixel format:
  PixelFormat get_pixel_format();

  // pixel access:
  bool lock_bits();
  void unlock_bits();
  std::uint8_t* get_bytes();
  std::size_t get_bytes_per_row();
  bool set_pixels(std::uint8_t* pixels);

  // save on disk:
  bool save_file(const std::string& full_path, BitmapType type);

public:
  std::uint8_t* _raw_data;
  std::size_t _width;
  std::size_t _height;
  std::size_t _stride;
  PixelFormat _pixel_format;
  bool _locked;

private:
  mutable std::recursive_mutex _mutex;
};

}  // namespace onis::core
