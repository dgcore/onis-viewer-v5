#ifndef OPJBUFFERDATA_H
#define OPJBUFFERDATA_H

#include <list>
// START MODIFY DIGITALCORE
#include <inttypes.h>
#include <stdio.h>
// END MODIFY DIGITALCORE

using namespace std;

// START MODIFY DIGITALCORE
#ifndef WIN32
typedef int8_t __int8;
typedef int64_t __int64;
typedef int32_t __int32;
typedef uint8_t __uint8;
typedef uint64_t __uint64;
typedef uint32_t __uint32;
#else
typedef unsigned __int8 __uint8;
#endif
// END MODIFY DIGITALCORE

struct opj_buffer_data {
  std::list<__uint8*> buffers;
  std::list<__uint8*>::iterator it;
  __int64 len;
  __int64 pos;         // position in the current packet
  __int64 it_index;    // zero based index of the current packet
  __int32 size_alloc;  // size of each packet

  // constructor:
  opj_buffer_data(int size_alloc);
  opj_buffer_data(unsigned char* indata, int size);
  opj_buffer_data(FILE* fp);
  ~opj_buffer_data();
  __int64 get_position();
  __int64 read(__uint8* p_buffer, __int64 p_nb_bytes);
  __int64 get_data_length();
  __int64 write(__uint8* p_buffer, __int64 p_nb_bytes);
  __int64 skip(__int64 p_nb_bytes);
  bool seek(__int64 p_nb_bytes);
};

#endif
