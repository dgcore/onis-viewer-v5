
#include "dcmtk/dcmjpeg/opjbufferdata.h"
#include "openjpeg.h"

// START MODIFY DIGITALCORE
#ifndef WIN32
#include <stdio.h>
#include <string.h>
#define _fseeki64(stream, offset, whence) (fseeko(stream, offset, whence))
#define _ftelli64(stream) (ftello(stream))
#endif
// END MODIFY DIGITALCORE

opj_buffer_data::opj_buffer_data(int size_alloc) {
  pos = 0;
  this->size_alloc = size_alloc;
  it = buffers.end();
  len = 0;
  it_index = -1;
}
opj_buffer_data::opj_buffer_data(unsigned char* indata, int size) {
  it_index = -1;
  pos = 0;
  size_alloc = 0;
  it = buffers.end();
  len = size;

  if (len > 0) {
    __uint8* buffer = new __uint8[len];
    memcpy(buffer, indata, size);
    buffers.push_back(buffer);

    it = buffers.begin();
    it_index = 0;
  }
}
opj_buffer_data::opj_buffer_data(FILE* fp) {
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
      __uint8* buffer = new __uint8[len];
      buffers.push_back(buffer);
      len = fread(buffer, 1, len, fp);
      it = buffers.begin();
      it_index = 0;
    }
  }
}

opj_buffer_data::~opj_buffer_data() {
  for (std::list<__uint8*>::iterator it = buffers.begin(); it != buffers.end();
       it++)
    delete[] *it;
}

__int64 opj_buffer_data::get_position() {
  if (it_index == -1)
    return -1;
  return it_index * size_alloc + pos;
}

__int64 opj_buffer_data::read(__uint8* p_buffer, __int64 p_nb_bytes) {
  __int64 ret;
  __int64 nb_bytes_written = 0;

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

__int64 opj_buffer_data::get_data_length() {
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

__int64 opj_buffer_data::write(__uint8* p_buffer, __int64 p_nb_bytes) {
  __int64 written = 0;
  if (it == buffers.end()) {
    __uint8* buffer = new __uint8[size_alloc];
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
      std::list<__uint8*>::iterator it1 = it;
      it1++;
      if (it1 == buffers.end()) {
        __uint8* buffer = new __uint8[size_alloc];
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

__int64 opj_buffer_data::skip(__int64 p_nb_bytes) {
  __int64 current = get_position();
  if (current == -1)
    current = 0;
  if (seek(p_nb_bytes + current))
    return p_nb_bytes;
  else
    return 0;
}

bool opj_buffer_data::seek(__int64 p_nb_bytes) {
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
