#include "precompiled_header.hpp"
#include "public/onis_j2k_kit.hpp"

#include "./openjpeg-2.0.0/src/lib/openjp2/openjpeg.h"
#include "buffer_stream.h"

#ifndef WIN32
#include <cstring>
#endif

#define J2K_CFMT 0
#define JP2_CFMT 1
#define JPT_CFMT 2

#define PXM_DFMT 10
#define PGX_DFMT 11
#define BMP_DFMT 12
#define YUV_DFMT 13
#define TIF_DFMT 14
#define RAW_DFMT 15
#define TGA_DFMT 16
#define PNG_DFMT 17
#define RAWL_DFMT 18

static inline int os_int_ceildivpow2(int a, int b) {
  int c = b;
  c = (1 << b);

  return (a + (1 << b) - 1) >> b;
}

os_j2k_decoder_output* os_decode_j2k_data(os_j2k_decoder_input* input) {
  os_j2k_decoder_output* output = NULL;

  if (input->data->get_data_length() >= 2) {
    std::uint8_t header[2];
    std::int64_t pos = input->data->get_position();
    input->data->read(header, 2);
    input->data->seek(pos);

    if (header[0] == 0xFF && header[1] == 0x4F) {
      // this is j2k type!
      opj_dparameters_t parameters;
      memset(&parameters, 0, sizeof(opj_dparameters_t));
      opj_image_t* image = NULL;
      opj_codec_t* dinfo = NULL;
      opj_stream_t* stream = NULL;

      strncpy(parameters.infile, "", sizeof(parameters.infile) - 1);
      strncpy(parameters.outfile, "", sizeof(parameters.outfile) - 1);
      parameters.decod_format = J2K_CFMT;
      parameters.cod_format = BMP_DFMT;
      parameters.cp_reduce =
          input->resolution_count;  // 5-> petite res | 0-> grande res
      parameters.cp_layer = input->layer_count;  // 1-> mauvaise qualite

      dinfo = opj_create_decompress(OPJ_CODEC_J2K);
      opj_setup_decoder(dinfo, &parameters);

      stream = os_opj_stream_create_default_buffer_stream(input->data, 1);
      if (opj_read_header(stream, dinfo, &image)) {
        if ((opj_decode(dinfo, stream, image) &&
             opj_end_decompress(dinfo, stream))) {
          output = new os_j2k_decoder_output;

          for (int compno = 0; compno < image->numcomps; compno++) {
            if (output == NULL)
              break;

            opj_image_comp_t* comp = &image->comps[compno];
            int w = image->comps[compno].w;
            int wr = w;  // os_int_ceildivpow2(image->comps[compno].w,
                         // image->comps[compno].factor);
            int numcomps = image->numcomps;
            int hr = image->comps[compno]
                         .h;  // os_int_ceildivpow2(image->comps[compno].h,
                              // image->comps[compno].factor);
            output->width = wr;
            output->height = hr;

            if (wr == w && numcomps == 1) {
              if (comp->prec <= 8) {
                output->bits_allocated = 8;
                output->len = wr * hr;
                output->data = new std::uint8_t[wr * hr];
                if (comp->sgnd == 0) {
                  output->signed_data = false;
                  for (std::int32_t i = 0; i < output->len; i++)
                    output->data[i] = (std::uint8_t)comp->data[i];

                } else {
                  output->signed_data = true;
                  for (std::int32_t i = 0; i < output->len; i++)
                    ((std::int8_t*)output->data)[i] =
                        (std::int8_t)comp->data[i];
                }

              } else if (comp->prec <= 16) {
                output->bits_allocated = 16;
                output->len = wr * hr * 2;
                output->data = new std::uint8_t[wr * hr * 2];
                if (comp->sgnd == 0) {
                  output->signed_data = false;
                  std::int32_t count = output->len / 2;
                  for (std::int32_t i = 0; i < count; i++)
                    ((std::uint16_t*)(output->data))[i] =
                        (std::uint16_t)comp->data[i];

                } else {
                  output->signed_data = true;
                  std::int32_t count = output->len / 2;
                  for (std::int32_t i = 0; i < count; i++)
                    ((std::int16_t*)(output->data))[i] =
                        (std::int16_t)comp->data[i];
                }

              } else {
                delete output;
                output = NULL;
                // printf( "****** 32-bit jpeg encoded is NOT supported\r");
                //			   uint32_t *data32 = (uint32_t*)raw + compno;
                //			   int *data = image->comps[compno].data;
                //			   int i = wr * hr;
                //			   while( i -- > 0)
                //				   *data32++ = (uint32_t) *data++;
                // }
              }

            } else {
              if (comp->prec <= 8) {
                output->bits_allocated = 8 * image->numcomps;
                output->signed_data = false;
                if (output->bits_allocated != 24) {
                  delete output;
                  output = NULL;

                } else {
                  if (input->rgb_format) {
                    std::int32_t stride = output->width * 3;
                    if (output->data == NULL) {
                      output->data = new std::uint8_t[stride * output->height];
                      output->len = stride * output->height;
                    }
                    for (std::int32_t j = 0; j < hr; j++) {
                      std::uint8_t* target_line = &output->data[stride * j];
                      OPJ_INT32* source_line = &comp->data[wr * j];
                      for (std::int32_t i = 0; i < wr; i++) {
                        if (source_line[i] < 0)
                          target_line[i * 3 + compno] = 0;
                        else if (source_line[i] > 255)
                          target_line[i * 3 + compno] = 255;
                        else
                          target_line[i * 3 + compno] =
                              (std::uint8_t)source_line[i];
                      }
                    }

                  } else {
                    if (output->data == NULL) {
                      output->data =
                          new std::uint8_t[output->width * output->height * 3];
                      output->len = output->width * output->height * 3;
                    }
                    std::int32_t count = output->width * output->height;
                    std::uint8_t* target = &output->data[compno * count];
                    OPJ_INT32* source = &comp->data[0];
                    for (std::int32_t i = 0; i < count; i++) {
                      if (source[i] < 0)
                        target[i] = 0;
                      else if (source[i] > 255)
                        target[i] = 255;
                      else
                        target[i] = (std::uint8_t)source[i];
                    }
                  }
                }

              } else if (comp->prec <= 16) {
                delete output;
                output = NULL;

                // Uint16 *data16 = (Uint16*)uncompressedFrameBuffer + compno;
                // for (int i = 0; i < wr * hr; i++) {

                //*data16 = (Uint16) (image->comps[compno].data[i / wr * w + i %
                // wr]); data16 += numcomps;

                //}

              } else {
                // printf( "****** 32-bit jpeg encoded is NOT supported\r");
                delete output;
                output = NULL;
              }
            }
          }
        }
      }
      if (image != NULL)
        opj_image_destroy(image);
      if (dinfo != NULL)
        opj_destroy_codec(dinfo);
      if (stream != NULL)
        opj_stream_destroy(stream);
    }
  }
  return output;
}