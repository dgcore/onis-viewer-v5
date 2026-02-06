#pragma once

namespace onis {

namespace fflags {
enum { begin = 0, current = 1, end = 2 };
}

class file {
public:
  virtual ~file() {}
  virtual std::uint32_t get_position() = 0;
  virtual void seek_to_end() = 0;
  virtual void seek(std::uint32_t position, int whence) = 0;
  virtual std::uint32_t read(std::uint8_t* buffer, std::uint32_t len) = 0;
  virtual std::uint32_t write(const std::uint8_t* buffer,
                              std::uint32_t len) = 0;
};

}  // namespace onis
