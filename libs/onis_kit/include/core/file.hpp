#pragma once

#include <cstdint>
#include <string>

namespace onis {

namespace fflags {
const std::uint32_t begin = 1;
const std::uint32_t current = 2;
const std::uint32_t end = 3;

const std::uint32_t create = 1;
const std::uint32_t read = 2;
const std::uint32_t write = 4;
const std::uint32_t read_write = 8;
const std::uint32_t text = 16;
const std::uint32_t binary = 32;
const std::uint32_t no_truncate = 64;
const std::uint32_t no_share_deny = 128;
}  // namespace fflags

class file;
typedef std::shared_ptr<file> file_ptr;
typedef std::weak_ptr<file> file_wptr;

///////////////////////////////////////////////////////////////////////
// file
///////////////////////////////////////////////////////////////////////

class file {
public:
  // static constructors:
  static file_ptr create_file();
  static file_ptr open_file(const std::string& path, std::uint32_t flags);

  // constructor:
  file();

  // destructor:
  virtual ~file();

  // prevent copying and assignment:
  file(const file&) = delete;
  file& operator=(const file&) = delete;
  file(file&&) = delete;
  file& operator=(file&&) = delete;

  // open and close:
  virtual bool open(const std::string& path, std::uint32_t flags);
  virtual void close();

  // read and write:
  virtual std::uint64_t read(void* buffer, std::uint64_t count);
  virtual std::uint64_t write(const void* buffer, std::uint64_t count);
  virtual void flush();

  // Position:
  virtual std::int64_t seek(std::int64_t offset, std::int64_t from);
  virtual void seek_to_begin();
  virtual void seek_to_end();
  virtual std::uint64_t get_position();

  // Properties:
  virtual bool is_open();
  virtual std::string get_file_path();

protected:
  // members:
  std::string _file_path;
#ifdef WIN32
  CFile _file;
#else
  FILE* _fp;
#endif
};

}  // namespace onis
