
#include "./bitmap_linux.hpp"
#include <png.h>
#include <cstdio>
#include <cstring>
#include "../../../include/utilities/filesystem.hpp"

namespace onis::core {

///////////////////////////////////////////////////////////////////////
// bitmap_linux
///////////////////////////////////////////////////////////////////////

bitmap_linux::bitmap_linux() {
  _locked = false;
  _raw_data = NULL;
  _width = 0;
  _height = 0;
  _stride = 0;
  _pixel_format = onis::core::PixelFormat::Unknown;
}

bitmap_linux::~bitmap_linux() {
  delete[] _raw_data;
}

bitmap_ptr bitmap_linux::clone() {
  _mutex.lock();
  bitmap_ptr ret = std::make_shared<bitmap_linux>();
  if (_raw_data != NULL) {
    bitmap_linux* tmp = (bitmap_linux*)ret.get();

    tmp->_width = _width;
    tmp->_height = _height;
    tmp->_pixel_format = _pixel_format;
    tmp->_stride = _stride;
    std::size_t len = _height * _stride;
    if (len > 0) {
      tmp->_raw_data = new std::uint8_t[len];
      memcpy(tmp->_raw_data, _raw_data, len);
    }
  }
  _mutex.unlock();
  return ret;
}

void* bitmap_linux::get_internal_data() {
  return _raw_data;
}

void bitmap_linux::set_internal_data(void* data, bool delete_old) {
  if (delete_old && data != _raw_data)
    delete[] _raw_data;
  _raw_data = (std::uint8_t*)data;
}

std::size_t bitmap_linux::get_width() {
  return _width;
}

std::size_t bitmap_linux::get_height() {
  return _height;
}

PixelFormat bitmap_linux::get_pixel_format() {
  return _pixel_format;
}

bool bitmap_linux::lock_bits() {
  bool ret = false;
  _mutex.lock();
  if (_raw_data && !_locked) {
    _locked = true;
    ret = true;
  }
  _mutex.unlock();
  return ret;
}

void bitmap_linux::unlock_bits() {
  _mutex.lock();
  if (_raw_data && _locked) {
    _locked = false;
  }
  _mutex.unlock();
}

std::uint8_t* bitmap_linux::get_bytes() {
  std::uint8_t* ret = NULL;
  _mutex.lock();
  if (_raw_data && _locked)
    ret = _raw_data;
  _mutex.unlock();
  return ret;
}

std::size_t bitmap_linux::get_bytes_per_row() {
  return _stride;
}

bool bitmap_linux::set_pixels(std::uint8_t* pixels) {
  if (!pixels)
    return false;
  _mutex.lock();
  bool ok = false;
  if (_raw_data && _locked) {
    std::size_t len = _height * _stride;
    if (len > 0) {
      memcpy(_raw_data, pixels, len);
      ok = true;
    }
  }
  _mutex.unlock();
  return ok;
}

bool bitmap_linux::save_file(const std::string& full_path, BitmapType type) {
  bool ret = false;
  if (type == BitmapType::Png) {
    png_structp png_ptr =
        png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    if (png_ptr == nullptr)
      return false;

    png_infop info_ptr = png_create_info_struct(png_ptr);
    if (info_ptr != nullptr) {
      if (!setjmp(png_jmpbuf(png_ptr))) {
        FILE* fp = fopen(full_path.data(), "wb");
        if (fp != nullptr) {
          png_init_io(png_ptr, fp);

          std::int32_t color_type = -1;
          switch (_pixel_format) {
            case PixelFormat::Argb32:
              color_type = PNG_COLOR_TYPE_RGBA;
              break;
            case PixelFormat::Rgb24:
              color_type = PNG_COLOR_TYPE_RGB;
              break;
            case PixelFormat::Rgba32:
              color_type = PNG_COLOR_TYPE_RGBA;
              break;
            default:
              break;
          };

          if (color_type != -1) {
            std::int32_t interlace_mode = PNG_INTERLACE_NONE;
            std::int32_t compression_type =
                PNG_COMPRESSION_TYPE_DEFAULT;  // PNG_COMPRESSION_TYPE_BASE
            std::int32_t filter_type =
                PNG_FILTER_TYPE_DEFAULT;  // PNG_FILTER_TYPE_BASE

            png_set_IHDR(png_ptr, info_ptr, _width, _height, 8, color_type,
                         interlace_mode, compression_type, filter_type);
            png_write_info(png_ptr, info_ptr);

            png_byte** volatile row_ptr = new png_bytep[_height];
            png_byte* pix_ptr;
            if (row_ptr != nullptr) {
              pix_ptr = _raw_data;  // OFstatic_cast(png_byte*,
                                    // OFconst_cast(void*, _raw_data));
              for (std::size_t row = 0; row < _height;
                   row++, pix_ptr += _stride)
                row_ptr[row] = pix_ptr;
              // write image
              png_write_image(png_ptr, row_ptr);
              // write additional chunks
              png_write_end(png_ptr, info_ptr);
              delete[] row_ptr;
              ret = true;
            }
          }
          fclose(fp);
          if (!ret)
            onis::util::filesystem::delete_file(full_path);
        }
      }
    }
    png_destroy_write_struct(&png_ptr, NULL);
  }
  return ret;
}

}  // namespace onis::core