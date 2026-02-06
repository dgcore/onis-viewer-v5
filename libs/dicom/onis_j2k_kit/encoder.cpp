#include "precompiled_header.hpp"
#include "public/onis_j2k_kit.hpp"

#include "./openjpeg-2.0.0/src/lib/openjp2/openjpeg.h"
#include "buffer_stream.h"

#include <cassert>
#ifndef WIN32
#include <cstring>
#endif

extern OPJ_BOOL find_layer_res_1(int** tab, int** dimensions, int res,
                                 int sample_pixel, opj_codec_t* p_codec,
                                 opj_stream_t* p_stream, opj_image_t* p_image,
                                 opj_dparameters_t* parameterspointeur);

template <typename T>
static void rawtoimage_fill(T* inputbuffer, int w, int h, int numcomps,
                            opj_image_t* image, int pc) {
  T* p = inputbuffer;
  if (pc) {
    for (int compno = 0; compno < numcomps; compno++) {
      for (int i = 0; i < w * h; i++) {
        /* compno : 0 = GREY, (0, 1, 2) = (R, G, B) */
        image->comps[compno].data[i] = *p;
        ++p;
      }
    }
  } else {
    for (int i = 0; i < w * h; i++) {
      for (int compno = 0; compno < numcomps; compno++) {
        /* compno : 0 = GREY, (0, 1, 2) = (R, G, B) */
        image->comps[compno].data[i] = *p;
        ++p;
      }
    }
  }
}

static opj_image_t* rawtoimage(std::uint8_t* inputbuffer,
                               opj_cparameters_t* parameters, int fragment_size,
                               int image_width, int image_height,
                               int sample_pixel, int bitsallocated,
                               int bitsstored, int sign, int pc) {
  int w, h;
  int numcomps;
  OPJ_COLOR_SPACE color_space;
  opj_image_cmptparm_t cmptparm[3]; /* maximum of 3 components */
  opj_image_t* image = NULL;

  if (sample_pixel == 1) {
    numcomps = 1;
    color_space = OPJ_CLRSPC_GRAY;

  } else {
    numcomps = 3;
    color_space = OPJ_CLRSPC_SRGB;
    // Does OpenJPEg support: CLRSPC_SYCC ??
  }

  if (bitsallocated % 8 != 0) {
    return 0;
  }

  assert(bitsallocated % 8 == 0);
  // eg. fragment_size == 63532 and 181 * 117 * 3 * 8 == 63531 ...
  assert(
      ((fragment_size + 1) / 2) * 2 ==
      ((image_height * image_width * numcomps * (bitsallocated / 8) + 1) / 2) *
          2);
  int subsampling_dx = parameters->subsampling_dx;
  int subsampling_dy = parameters->subsampling_dy;

  // FIXME
  w = image_width;
  h = image_height;

  /* initialize image components */
  memset(&cmptparm[0], 0, 3 * sizeof(opj_image_cmptparm_t));
  // assert( bitsallocated == 8 );
  for (int i = 0; i < numcomps; i++) {
    cmptparm[i].prec = bitsstored;
    cmptparm[i].bpp = bitsallocated;
    cmptparm[i].sgnd = sign;
    cmptparm[i].dx = subsampling_dx;
    cmptparm[i].dy = subsampling_dy;
    cmptparm[i].w = w;
    cmptparm[i].h = h;
  }

  // create the image
  image = opj_image_create(numcomps, &cmptparm[0], color_space);
  if (!image)
    return NULL;

  // set image offset and reference grid
  image->x0 = parameters->image_offset_x0;
  image->y0 = parameters->image_offset_y0;
  image->x1 = parameters->image_offset_x0 + (w - 1) * subsampling_dx + 1;
  image->y1 = parameters->image_offset_y0 + (h - 1) * subsampling_dy + 1;

  // set image data
  // assert( fragment_size == numcomps*w*h*(bitsallocated/8) );
  if (bitsallocated <= 8) {
    if (sign)
      rawtoimage_fill<std::int8_t>((std::int8_t*)inputbuffer, w, h, numcomps,
                                   image, pc);
    else
      rawtoimage_fill<std::uint8_t>((std::uint8_t*)inputbuffer, w, h, numcomps,
                                    image, pc);

  } else if (bitsallocated <= 16) {
    if (sign)
      rawtoimage_fill<std::int16_t>((std::int16_t*)inputbuffer, w, h, numcomps,
                                    image, pc);
    else
      rawtoimage_fill<std::uint16_t>((std::uint16_t*)inputbuffer, w, h,
                                     numcomps, image, pc);

  } else if (bitsallocated <= 32) {
    if (sign)
      rawtoimage_fill<std::int32_t>((std::int32_t*)inputbuffer, w, h, numcomps,
                                    image, pc);
    else
      rawtoimage_fill<std::uint32_t>((std::uint32_t*)inputbuffer, w, h,
                                     numcomps, image, pc);

  } else {
    opj_image_destroy(image);
    return NULL;
  }
  return image;
}

bool os_find_resolution_layout_offsets(os_j2k_encoder_input* input,
                                       os_j2k_encoder_output* output) {
  bool result = false;

  opj_image_t* image = NULL;
  opj_stream_t* l_stream = NULL; /* Stream */
  opj_codec_t* l_codec = NULL;   /* Handle to a decompressor */

  opj_dparameters_t parameters;
  opj_set_default_decoder_parameters(&parameters);
  parameters.cp_reduce = 0;
  parameters.cp_layer = input->layer_count;  // 1-> mauvaise qualite
  parameters.decod_format = 0;
  parameters.cod_format = 12;

  l_stream = os_opj_stream_create_default_buffer_stream(output->data, OPJ_TRUE);
  if (l_stream != NULL) {
    l_codec = opj_create_decompress(OPJ_CODEC_J2K);
    if (opj_setup_decoder(l_codec, &parameters)) {
      if (opj_read_header(l_stream, l_codec, &image)) {
        if (!parameters.nb_tile_to_decode) {
          // Optional if you want decode the entire image */
          // if (opj_set_decode_area(l_codec, image, parameters.DA_x0,
          // parameters.DA_y0, parameters.DA_x1, parameters.DA_y1)) ok =
          // false;

          if (find_layer_res_1(&output->resolution_layer_offsets,
                               &output->dimensions, input->resolution_count,
                               input->sample_per_pixels, l_codec, l_stream,
                               image, &parameters)) {
            output->resolution_layer_offsets[input->resolution_count *
                                                 input->layer_count -
                                             1] = output->data->len;
            output->layer_count = input->layer_count;
            output->resolution_count = input->resolution_count;
            output->progression_order = input->progression_order;

            result = true;
          }
        }
      }
    }
  }

  if (image != NULL)
    opj_image_destroy(image);
  if (l_stream != NULL)
    opj_stream_destroy(l_stream);
  if (l_codec != NULL)
    opj_destroy_codec(l_codec);

  return result;
}

os_j2k_encoder_output* os_create_j2k_streaming_data(
    os_j2k_encoder_input* input) {
  os_j2k_encoder_output* output = NULL;

  // init:
  opj_cparameters_t parameters;
  opj_image_t* image = NULL;
  opj_set_default_encoder_parameters(&parameters);
  parameters.cp_disto_alloc = 1;
  parameters.cod_format = OPJ_CODEC_J2K;
  parameters.tcp_numlayers = input->layer_count;
  for (std::int32_t i = 0; i < input->layer_count; i++)
    parameters.tcp_rates[i] = input->layer_qualities[i];

  // create the image:
  image = rawtoimage(input->data, &parameters,
                     static_cast<std::int32_t>(input->columns * input->rows *
                                               input->sample_per_pixels *
                                               input->bits_allocated / 8),
                     input->columns, input->rows, input->sample_per_pixels,
                     input->bits_allocated, input->bits_used,
                     input->signed_data, input->pc);

  // create the compression object:
  opj_codec_t* cinfo = opj_create_compress(OPJ_CODEC_J2K);

  // catch events using our callbacks and give a local context
  // opj_set_event_mgr((opj_common_ptr)cinfo, &event_mgr, stderr);

  // setup the encoder parameters using the current image and using user
  // parameters
  opj_setup_encoder(cinfo, &parameters, image);

  // open a byte stream for writing
  // allocate memory for all tiles
  os_opj_buffer_data* data = new os_opj_buffer_data(8192);
  opj_stream_t* l_stream =
      os_opj_stream_create_default_buffer_stream(data, OPJ_FALSE);
  if (l_stream != NULL) {
    // encode the image
    int ok = opj_start_compress(cinfo, image, l_stream);
    if (ok)
      ok = opj_encode(cinfo, l_stream);
    if (ok)
      ok = opj_end_compress(cinfo, l_stream);
    if (ok) {
      output = new os_j2k_encoder_output;
      output->data = data;
      output->data->seek(0);
      data = NULL;
      if (!os_find_resolution_layout_offsets(input, output)) {
        delete output;
        output = NULL;
      }
    }
  }
  if (l_stream != NULL)
    opj_stream_destroy(l_stream);
  if (cinfo != NULL)
    opj_destroy_codec(cinfo);
  if (image != NULL)
    opj_image_destroy(image);
  if (data != NULL)
    delete data;
  return output;
}
