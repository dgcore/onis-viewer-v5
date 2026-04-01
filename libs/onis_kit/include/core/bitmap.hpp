#pragma once

#include <cstdint>
#include <memory>
#include <string>

namespace onis::core {

enum class PixelFormat { Unknown = 0, Argb32 = 1, Rgb24 = 2, Rgba32 = 3 };

enum class BitmapType { Dicom = 0, Bmp = 1, Jpg = 2, Tiff = 3, Png = 4 };

///////////////////////////////////////////////////////////////////////
// bitmap
///////////////////////////////////////////////////////////////////////

class bitmap;
typedef std::shared_ptr<bitmap> bitmap_ptr;
typedef std::weak_ptr<bitmap> bitmap_wptr;

class bitmap : public std::enable_shared_from_this<bitmap> {
public:
  static bitmap_ptr create(void* internal_data);
  static bitmap_ptr create(std::size_t width, std::size_t height,
                           PixelFormat pixel_format);

  // clone:
  virtual bitmap_ptr clone() = 0;

  virtual ~bitmap() = default;

  // internal data:
  virtual void* get_internal_data() = 0;
  virtual void set_internal_data(void* data, bool delete_old) = 0;

  // Dimension:
  virtual std::size_t get_width() = 0;
  virtual std::size_t get_height() = 0;

  // pixel format:
  virtual PixelFormat get_pixel_format() = 0;

  // pixel access:
  virtual bool lock_bits() = 0;
  virtual void unlock_bits() = 0;
  virtual std::uint8_t* get_bytes() = 0;
  virtual std::size_t get_bytes_per_row() = 0;
  virtual bool set_pixels(std::uint8_t* pixels) = 0;

  // save on disk:
  virtual bool save_file(const std::string& full_path, BitmapType type) = 0;

protected:
  // constructor:
  bitmap() = default;
};

}  // namespace onis::core
