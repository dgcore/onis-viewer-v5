#include "../../include/core/file.hpp"

namespace onis {

///////////////////////////////////////////////////////////////////////
// file
///////////////////////////////////////////////////////////////////////

//-----------------------------------------------------------------------
// static creators
//-----------------------------------------------------------------------
file_ptr file::create_file() {
  file_ptr fp = std::make_shared<file>();
  return fp;
}

file_ptr file::open_file(const std::string& path, std::uint32_t flags) {
  file_ptr fp = file::create_file();
  if (fp != nullptr) {
    if (!fp->open(path, flags)) {
      fp.reset();
    }
  }
  return fp;
}

//-----------------------------------------------------------------------
// constructor
//-----------------------------------------------------------------------
file::file() {
#ifdef WIN32
#else
  _fp = nullptr;
#endif
}

//-----------------------------------------------------------------------
// destructor
//-----------------------------------------------------------------------
file::~file() {
#ifdef WIN32
  if (_file.m_hFile != INVALID_HANDLE_VALUE)
    _file.Close();
#else
  if (_fp != NULL) {
    fclose(_fp);
    _fp = nullptr;
  }
#endif
}

//-----------------------------------------------------------------------
// open and close
//-----------------------------------------------------------------------
bool file::open(const std::string& path, std::uint32_t flags) {
#ifdef WIN32
  u32 mfc_flags = 0;
  if (flags & onis::fflags::create)
    mfc_flags |= CFile::modeCreate;
  if (flags & onis::fflags::read)
    mfc_flags |= CFile::modeRead;
  if (flags & onis::fflags::write)
    mfc_flags |= CFile::modeWrite;
  if (flags & onis::fflags::read_write)
    mfc_flags |= CFile::modeReadWrite;
  if (flags & onis::fflags::text)
    mfc_flags |= CFile::typeText;
  if (flags & onis::fflags::binary)
    mfc_flags |= CFile::typeBinary;
  if (flags & onis::fflags::no_truncate)
    mfc_flags |= CFile::modeNoTruncate;
  if (flags & onis::fflags::no_share_deny)
    mfc_flags |= CFile::shareDenyNone;

  if (_file.Open(path.data(), mfc_flags)) {
    if (flags & onis::fflags::no_truncate)
      seek_to_end();
    _file_path = path;
    return OSTRUE;
  } else
    return OSFALSE;
#else
  std::string open_flags;
  if (flags & onis::fflags::read)
    open_flags += "r";
  if (flags & onis::fflags::write)
    open_flags += "w";
  if (flags & onis::fflags::read_write)
    open_flags += "wr+";
  if (flags & onis::fflags::binary)
    open_flags += "b";
  if (_fp != nullptr)
    fclose(_fp);
  _fp = fopen(path.data(), open_flags.data());
  if (_fp != nullptr) {
    _file_path = path;
    return true;
  } else {
    return false;
  }
#endif
}

void file::close() {
#if WIN32
  if (_file.m_hFile != INVALID_HANDLE_VALUE)
    _file.Close();
#else
  if (_fp != NULL) {
    fclose(_fp);
    _fp = nullptr;
  }
#endif
  _file_path = "";
}

//-----------------------------------------------------------------------
// read and write
//-----------------------------------------------------------------------
std::uint64_t file::read(void* buffer, std::uint64_t count) {
#if WIN32
  return _file.Read(buffer, count);
#else
  return (std::uint64_t)fread(buffer, 1, count, _fp);
#endif
}

std::uint64_t file::write(const void* buffer, std::uint64_t count) {
#ifdef WIN32
  try {
    _file.Write(buffer, count);
    return count;

  } catch (CFileException* e) {
    e->Delete();
    return 0;
  }
#else
  return (std::uint64_t)fwrite(buffer, 1, count, _fp);
#endif
}

void file::flush() {
#ifdef WIN32
  _file.Flush();
#else
  fflush(_fp);
#endif
}

//-----------------------------------------------------------------------
// Position
//-----------------------------------------------------------------------
std::int64_t file::seek(std::int64_t offset, std::int64_t from) {
#ifdef WIN32
  switch (from) {
    case onis::fflags::begin:
      return _file.Seek(offset, CFile::begin);
    case onis::fflags::current:
      return _file.Seek(offset, CFile::current);
    case onis::fflags::end:
      return _file.Seek(offset, CFile::end);
    default:
      return 0;
  };
#else
  switch (from) {
    case onis::fflags::begin:
      return fseek(_fp, offset, SEEK_SET);
    case onis::fflags::current:
      return fseek(_fp, offset, SEEK_CUR);
    case onis::fflags::end:
      return fseek(_fp, offset, SEEK_END);
    default:
      return 0;
  }
#endif
}

void file::seek_to_begin() {
#ifdef WIN32
  _file.SeekToBegin();
#else
  fseek(_fp, 0, SEEK_SET);
#endif
}

void file::seek_to_end() {
#ifdef WIN32
  _file.SeekToEnd();
#else
  fseek(_fp, 0, SEEK_END);
#endif
}

std::uint64_t file::get_position() {
#ifdef WIN32
  return _file.GetPosition();
#else
  return ftell(_fp);
#endif
}

//-----------------------------------------------------------------------
// Properties
//-----------------------------------------------------------------------
bool file::is_open() {
#ifdef WIN32
  if (_file.m_hFile != INVALID_HANDLE_VALUE)
    return OSTRUE;
  else
    return OSFALSE;
#else
  return _fp != nullptr;
#endif
}

std::string file::get_file_path() {
  return _file_path;
}

}  // namespace onis
