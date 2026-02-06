#pragma once

namespace onis {

class file;
typedef std::shared_ptr<file> file_ptr;
typedef std::weak_ptr<file> file_wptr;

}  // namespace onis

///////////////////////////////////////////////////////////////////////
// os_opj_buffer_data
///////////////////////////////////////////////////////////////////////

struct os_opj_buffer_data {
  std::list<std::uint8_t*> buffers;
  std::list<std::uint8_t*>::iterator it;
  std::int64_t len;
  std::int64_t pos;         // position in the current packet
  std::int64_t it_index;    // zero based index of the current packet
  std::int32_t size_alloc;  // size of each packet

  // constructor:
  os_opj_buffer_data(int size_alloc);
  os_opj_buffer_data(FILE* fp);
  os_opj_buffer_data(onis::file_ptr& fp, std::uint32_t len = 0);
  ~os_opj_buffer_data();
  std::int64_t get_position();
  std::int64_t read(std::uint8_t* p_buffer, std::int64_t p_nb_bytes);
  std::int64_t get_data_length();
  std::int64_t write(std::uint8_t* p_buffer, std::int64_t p_nb_bytes);
  std::int64_t skip(std::int64_t p_nb_bytes);
  bool seek(std::int64_t p_nb_bytes);
  // bool fwrite_from_opj_buffer_data(FILE* fp);
  bool fwrite_from_opj_buffer_data(onis::file_ptr& fp);
};

///////////////////////////////////////////////////////////////////////
// os_j2k_encoder_input
///////////////////////////////////////////////////////////////////////

struct os_j2k_encoder_input {
  std::uint32_t columns;
  std::uint32_t rows;
  std::uint16_t sample_per_pixels;
  std::uint8_t bits_allocated;
  std::uint8_t bits_used;
  bool signed_data;
  std::uint8_t* data;
  std::uint8_t progression_order;  // 0->LRCP, 1->RLCP
  std::uint8_t resolution_count;
  std::uint8_t layer_count;  // 1 to 100
  float layer_qualities[100];
  std::uint8_t pc;
};

///////////////////////////////////////////////////////////////////////
// os_j2k_encoder_output
///////////////////////////////////////////////////////////////////////

struct os_j2k_encoder_output {
  os_opj_buffer_data* data;
  std::int32_t layer_count;
  std::int32_t resolution_count;
  std::int32_t* resolution_layer_offsets;
  std::int32_t* dimensions;
  std::uint8_t progression_order;

  os_j2k_encoder_output() {
    progression_order = 0;
    layer_count = 0;
    resolution_count = 0;
    data = NULL;
    resolution_layer_offsets = NULL;
    dimensions = NULL;
  }
  ~os_j2k_encoder_output() {
    if (data != NULL)
      delete data;
    if (resolution_layer_offsets != NULL)
      delete[] resolution_layer_offsets;
    if (dimensions != NULL)
      delete[] dimensions;
  }
};

///////////////////////////////////////////////////////////////////////
// os_j2k_decoder_input
///////////////////////////////////////////////////////////////////////

struct os_j2k_decoder_input {
  os_opj_buffer_data* data;
  std::int32_t layer_count;
  std::int32_t resolution_count;
  bool rgb_format;
};

///////////////////////////////////////////////////////////////////////
// os_j2k_encoder_output
///////////////////////////////////////////////////////////////////////

struct os_j2k_decoder_output {
  std::uint8_t* data;
  std::uint32_t len;
  std::int32_t width;
  std::int32_t height;
  bool signed_data;
  std::uint8_t bits_allocated;

  os_j2k_decoder_output() {
    data = NULL;
    len = 0;
  }
  ~os_j2k_decoder_output() {
    if (data != NULL)
      delete[] data;
  }
};

///////////////////////////////////////////////////////////////////////
// encoding/decoding
///////////////////////////////////////////////////////////////////////

os_j2k_encoder_output* os_create_j2k_streaming_data(
    os_j2k_encoder_input* input);
os_j2k_decoder_output* os_decode_j2k_data(os_j2k_decoder_input* input);
