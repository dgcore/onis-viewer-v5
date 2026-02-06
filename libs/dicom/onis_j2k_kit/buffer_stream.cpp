#include "../../onis_kit/include/core/file.hpp"
#include "precompiled_header.hpp"
#include "public/onis_j2k_kit.hpp"

#include "./openjpeg-2.0.0/src/lib/openjp2/openjpeg.h"
#include "buffer_stream.h"

#ifndef WIN32
#include <cstring>
#define _fseeki64(stream, offset, whence) (fseeko(stream, offset, whence))
#define _ftelli64(stream) (ftello(stream))
#endif

///////////////////////////////////////////////////////////////////////
// os_opj_buffer_data
///////////////////////////////////////////////////////////////////////

os_opj_buffer_data::os_opj_buffer_data(int size_alloc) {
  pos = 0;
  this->size_alloc = size_alloc;
  it = buffers.end();
  len = 0;
  it_index = -1;
}

os_opj_buffer_data::os_opj_buffer_data(FILE* fp) {
  it_index = -1;
  pos = 0;
  size_alloc = 0;
  it = buffers.end();
  len = 0;
  if (fp != NULL) {
    _fseeki64(fp, 0, SEEK_END);
    len = (int)_ftelli64(fp);
    _fseeki64(fp, 0, SEEK_SET);

    if (len > 0) {
      std::uint8_t* buffer = new std::uint8_t[len];
      buffers.push_back(buffer);
      len = fread(buffer, 1, len, fp);
      it = buffers.begin();
      it_index = 0;
    }
  }
}

os_opj_buffer_data::os_opj_buffer_data(onis::file_ptr& fp,
                                       std::uint32_t count) {
  it_index = -1;
  pos = 0;
  size_alloc = 0;
  it = buffers.end();
  len = 0;

  if (fp != NULL) {
    std::uint32_t position = (std::uint32_t)fp->get_position();
    std::uint32_t len_to_copy = 0;
    fp->seek_to_end();
    if (fp->get_position() > position) {
      len_to_copy = fp->get_position() - position;
      if (len_to_copy > count)
        len_to_copy = count;
      fp->seek(position, onis::fflags::begin);

      len = len_to_copy;
      std::uint8_t* buffer = new std::uint8_t[len];
      buffers.push_back(buffer);
      len = fp->read(buffer, len);
      it = buffers.begin();
      it_index = 0;
      size_alloc = len;

    } else
      fp->seek(position, onis::fflags::begin);
  }
}

os_opj_buffer_data::~os_opj_buffer_data() {
  for (std::list<std::uint8_t*>::iterator it = buffers.begin();
       it != buffers.end(); it++)
    delete[] *it;
}

std::int64_t os_opj_buffer_data::get_position() {
  if (it_index == -1)
    return -1;
  return it_index * size_alloc + pos;
}

std::int64_t os_opj_buffer_data::read(std::uint8_t* p_buffer,
                                      std::int64_t p_nb_bytes) {
  std::int64_t ret;
  std::int64_t nb_bytes_written = 0;

  if (get_position() == -1)
    ret = -1;
  else if (get_position() + p_nb_bytes > len) {
    ret = len - get_position();
    p_nb_bytes = ret;
    while (p_nb_bytes) {
      if (p_nb_bytes < size_alloc - pos) {
        memcpy(&p_buffer[nb_bytes_written], &(*it)[pos], p_nb_bytes);
        nb_bytes_written += p_nb_bytes;
        p_nb_bytes = 0;
        it++;
        break;

      } else {
        memcpy(&p_buffer[nb_bytes_written], &(*it)[pos], size_alloc - pos);
        nb_bytes_written += size_alloc - pos;
        p_nb_bytes -= size_alloc - pos;
        it++;
        it_index++;
        pos = 0;
      }
    }
    it_index = -1;
    pos = 0;

  } else {
    ret = p_nb_bytes;
    while (p_nb_bytes) {
      if (p_nb_bytes < size_alloc - pos) {
        memcpy(&p_buffer[nb_bytes_written], &(*it)[pos], p_nb_bytes);
        nb_bytes_written += p_nb_bytes;
        pos += p_nb_bytes;
        p_nb_bytes = 0;
        break;

      } else {
        memcpy(&p_buffer[nb_bytes_written], &(*it)[pos], size_alloc - pos);
        nb_bytes_written += size_alloc - pos;
        p_nb_bytes -= size_alloc - pos;
        it++;
        it_index++;
        pos = 0;
      }
    }
  }
  return ret;
}

std::int64_t os_opj_buffer_data::get_data_length() {
  pos = 0;
  if (buffers.empty()) {
    it = buffers.end();
    it_index = -1;

  } else {
    it = buffers.begin();
    it_index = 0;
  }
  return len;
}

std::int64_t os_opj_buffer_data::write(std::uint8_t* p_buffer,
                                       std::int64_t p_nb_bytes) {
  std::int64_t written = 0;
  if (it == buffers.end()) {
    std::uint8_t* buffer = new std::uint8_t[size_alloc];
    buffers.push_back(buffer);
    it = buffers.begin();
    it_index = 0;
  }

  while (p_nb_bytes) {
    if (p_nb_bytes < size_alloc - pos) {
      if (p_buffer == NULL)
        memset(&(*it)[pos], 0, p_nb_bytes);
      else
        memcpy(&(*it)[pos], &(p_buffer[written]), p_nb_bytes);
      pos += p_nb_bytes;
      written += p_nb_bytes;
      break;

    } else {
      // p_nb_bytes >= size_alloc
      if (p_buffer == NULL)
        memset(&(*it)[pos], 0, size_alloc - pos);
      else
        memcpy(&(*it)[pos], &(p_buffer[written]), size_alloc - pos);
      p_nb_bytes -= (size_alloc - pos);
      written += (size_alloc - pos);

      pos = 0;
      it_index++;
      std::list<std::uint8_t*>::iterator it1 = it;
      it1++;
      if (it1 == buffers.end()) {
        std::uint8_t* buffer = new std::uint8_t[size_alloc];
        buffers.push_back(buffer);
        it++;

      } else
        it = it1;
    }
  }

  if (get_position() > len)
    len = get_position();
  return written;
}

std::int64_t os_opj_buffer_data::skip(std::int64_t p_nb_bytes) {
  std::int64_t current = get_position();
  if (current == -1)
    current = 0;
  if (seek(p_nb_bytes + current))
    return p_nb_bytes;
  else
    return 0;
}

bool os_opj_buffer_data::seek(std::int64_t p_nb_bytes) {
  if (p_nb_bytes > len) {
    if (buffers.empty()) {
      write(NULL, p_nb_bytes);

    } else {
      it_index = len / size_alloc;
      it = buffers.begin();
      std::advance(it, it_index);
      pos = len - it_index * size_alloc;
      write(NULL, p_nb_bytes - len);
    }

  } else {
    it_index = p_nb_bytes / size_alloc;
    it = buffers.begin();
    std::advance(it, it_index);
    pos = p_nb_bytes - it_index * size_alloc;
  }
  return true;
}

/*bool os_opj_buffer_data::fwrite_from_opj_buffer_data(FILE* fp) {

  std::int64_t last_size = 0;
  std::int64_t count = len / size_alloc;
  if (count * size_alloc != len) {

    last_size = len - count * size_alloc;
    count++;

  }

  std::int64_t data_written = 0;
  std::int64_t index = 0;
  for (std::list<std::uint8_t *>::iterator it1 = buffers.begin(); it1 !=
buffers.end(); it1++) {

    std::int64_t size = (index == count-1) ? last_size : size_alloc;
    index++;
    data_written += fwrite((*it1), 1, size, fp);

  }
  return (data_written) ? true : false;

}*/

bool os_opj_buffer_data::fwrite_from_opj_buffer_data(onis::file_ptr& fp) {
  std::int64_t last_size = 0;
  std::int64_t count = len / size_alloc;
  if (count * size_alloc != len) {
    last_size = len - count * size_alloc;
    count++;
  }

  std::int64_t data_written = 0;
  std::int64_t index = 0;
  for (std::list<std::uint8_t*>::iterator it1 = buffers.begin();
       it1 != buffers.end(); it1++) {
    std::int64_t size = (index == count - 1) ? last_size : size_alloc;
    index++;
    data_written += fp->write((*it1), size);
  }
  return (data_written) ? true : false;
}

///////////////////////////////////////////////////////////////////////
// operations
///////////////////////////////////////////////////////////////////////

static OPJ_SIZE_T os_opj_read_from_buffer(void* p_buffer, OPJ_SIZE_T p_nb_bytes,
                                          os_opj_buffer_data* p_buffer_data) {
  return p_buffer_data->read((std::uint8_t*)p_buffer, p_nb_bytes);
}

OPJ_UINT64 os_opj_get_data_length_from_buffer(
    os_opj_buffer_data* p_buffer_data) {
  return p_buffer_data->get_data_length();
}

static OPJ_SIZE_T os_opj_write_from_buffer(void* p_buffer,
                                           OPJ_SIZE_T p_nb_bytes,
                                           os_opj_buffer_data* p_buffer_data) {
  return p_buffer_data->write((std::uint8_t*)p_buffer, p_nb_bytes);
}

static OPJ_OFF_T os_opj_skip_from_buffer(OPJ_OFF_T p_nb_bytes,
                                         os_opj_buffer_data* p_buffer_data) {
  return p_buffer_data->skip(p_nb_bytes);
}

static OPJ_BOOL os_opj_seek_from_buffer(OPJ_OFF_T p_nb_bytes,
                                        os_opj_buffer_data* p_buffer_data) {
  return p_buffer_data->seek(p_nb_bytes);
}

static opj_stream_t* OPJ_CALLCONV os_opj_stream_create_buffer_stream(
    os_opj_buffer_data* p_buffer, OPJ_SIZE_T p_size,
    OPJ_BOOL p_is_read_stream) {
  opj_stream_t* l_stream = 00;

  if (p_buffer == NULL) {
    return NULL;
  }

  l_stream = opj_stream_create(p_size, p_is_read_stream);
  if (!l_stream) {
    return NULL;
  }

  opj_stream_set_user_data(l_stream, p_buffer);
  opj_stream_set_user_data_length(l_stream,
                                  os_opj_get_data_length_from_buffer(p_buffer));
  opj_stream_set_read_function(l_stream,
                               (opj_stream_read_fn)os_opj_read_from_buffer);
  opj_stream_set_write_function(l_stream,
                                (opj_stream_write_fn)os_opj_write_from_buffer);
  opj_stream_set_skip_function(l_stream,
                               (opj_stream_skip_fn)os_opj_skip_from_buffer);
  opj_stream_set_seek_function(l_stream,
                               (opj_stream_seek_fn)os_opj_seek_from_buffer);

  // opj_stream_private_t* p_stream = (opj_stream_private_t*) l_stream;

  return l_stream;
}

opj_stream_t* OPJ_CALLCONV os_opj_stream_create_default_buffer_stream(
    os_opj_buffer_data* p_buffer, OPJ_BOOL p_is_read_stream) {
  return os_opj_stream_create_buffer_stream(p_buffer, OPJ_J2K_STREAM_CHUNK_SIZE,
                                            p_is_read_stream);
}
