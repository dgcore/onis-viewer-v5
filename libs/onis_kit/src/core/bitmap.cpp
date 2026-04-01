#pragma once

#include "../../include/core/bitmap.hpp"

namespace onis::core {

///////////////////////////////////////////////////////////////////////
// bitmap
///////////////////////////////////////////////////////////////////////

bitmap_ptr bitmap::create(void* internal_data) {
  return nullptr;
}

bitmap_ptr bitmap::create(std::size_t width, std::size_t height,
                          PixelFormat pixel_format) {
  return nullptr;
}

}  // namespace onis::core
