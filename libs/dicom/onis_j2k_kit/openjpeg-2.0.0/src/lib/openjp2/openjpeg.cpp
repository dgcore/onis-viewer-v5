/*
 * Copyright (c) 2005, Herve Drolon, FreeImage Team
 * Copyright (c) 2008;2011-2012, Centre National d'Etudes Spatiales (CNES),
 * France Copyright (c) 2012, CS Systemes d'Information, France All rights
 * reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#ifdef _WIN32
#include <windows.h>
#endif /* _WIN32 */

#include "opj_config.h"
#include "opj_includes.h"

/**
 * Decompression handler.
 */
typedef struct opj_decompression {
  /** Main header reading function handler*/
  OPJ_BOOL (*opj_read_header)(struct opj_stream_private* cio, void* p_codec,
                              opj_image_t** p_image,
                              struct opj_event_mgr* p_manager);
  /** Decoding function */
  OPJ_BOOL (*opj_decode)(void* p_codec, struct opj_stream_private* p_cio,
                         opj_image_t* p_image, struct opj_event_mgr* p_manager);
  /** FIXME DOC */
  OPJ_BOOL (*opj_read_tile_header)(
      void* p_codec, OPJ_UINT32* p_tile_index, OPJ_UINT32* p_data_size,
      OPJ_INT32* p_tile_x0, OPJ_INT32* p_tile_y0, OPJ_INT32* p_tile_x1,
      OPJ_INT32* p_tile_y1, OPJ_UINT32* p_nb_comps, OPJ_BOOL* p_should_go_on,
      struct opj_stream_private* p_cio, struct opj_event_mgr* p_manager);
  /** FIXME DOC */
  OPJ_BOOL (*opj_decode_tile_data)(void* p_codec, OPJ_UINT32 p_tile_index,
                                   OPJ_BYTE* p_data, OPJ_UINT32 p_data_size,
                                   struct opj_stream_private* p_cio,
                                   struct opj_event_mgr* p_manager);
  /** Reading function used after codestream if necessary */
  OPJ_BOOL (*opj_end_decompress)(void* p_codec, struct opj_stream_private* cio,
                                 struct opj_event_mgr* p_manager);
  /** Codec destroy function handler*/
  void (*opj_destroy)(void* p_codec);
  /** Setup decoder function handler */
  void (*opj_setup_decoder)(void* p_codec, opj_dparameters_t* p_param);
  /** Set decode area function handler */
  OPJ_BOOL (*opj_set_decode_area)(void* p_codec, opj_image_t* p_image,
                                  OPJ_INT32 p_start_x, OPJ_INT32 p_end_x,
                                  OPJ_INT32 p_start_y, OPJ_INT32 p_end_y,
                                  struct opj_event_mgr* p_manager);

  /** Get tile function */
  OPJ_BOOL (*opj_get_decoded_tile)(void* p_codec, opj_stream_private_t* p_cio,
                                   opj_image_t* p_image,
                                   struct opj_event_mgr* p_manager,
                                   OPJ_UINT32 tile_index);

  /** Set the decoded resolution factor */
  OPJ_BOOL (*opj_set_decoded_resolution_factor)(void* p_codec,
                                                OPJ_UINT32 res_factor,
                                                opj_event_mgr_t* p_manager);

} opj_decompression_t;

/**
 * Compression handler. FIXME DOC
 */
typedef struct opj_compression {
  OPJ_BOOL (*opj_start_compress)(void* p_codec, struct opj_stream_private* cio,
                                 struct opj_image* p_image,
                                 struct opj_event_mgr* p_manager);

  OPJ_BOOL (*opj_encode)(void* p_codec, struct opj_stream_private* p_cio,
                         struct opj_event_mgr* p_manager);

  OPJ_BOOL (*opj_write_tile)(void* p_codec, OPJ_UINT32 p_tile_index,
                             OPJ_BYTE* p_data, OPJ_UINT32 p_data_size,
                             struct opj_stream_private* p_cio,
                             struct opj_event_mgr* p_manager);

  OPJ_BOOL (*opj_end_compress)(void* p_codec, struct opj_stream_private* p_cio,
                               struct opj_event_mgr* p_manager);

  void (*opj_destroy)(void* p_codec);

  void (*opj_setup_encoder)(void* p_codec, opj_cparameters_t* p_param,
                            struct opj_image* p_image,
                            struct opj_event_mgr* p_manager);

} opj_compression_t;

/**
 * Main codec handler used for compression or decompression.
 */
typedef struct opj_codec_private {
  /** FIXME DOC */
  union {
    opj_decompression_t m_decompression;
    opj_compression_t m_compression;
  } m_codec_data;
  /** FIXME DOC*/
  void* m_codec;
  /** Event handler */
  opj_event_mgr_t m_event_mgr;
  /** Flag to indicate if the codec is used to decode or encode*/
  OPJ_BOOL is_decompressor;
  void (*opj_dump_codec)(void* p_codec, OPJ_INT32 info_flag,
                         FILE* output_stream);
  opj_codestream_info_v2_t* (*opj_get_codec_info)(void* p_codec);
  opj_codestream_index_t* (*opj_get_codec_index)(void* p_codec);
} opj_codec_private_t;

/* ---------------------------------------------------------------------- */
/* Functions to set the message handlers */

OPJ_BOOL OPJ_CALLCONV opj_set_info_handler(opj_codec_t* p_codec,
                                           opj_msg_callback p_callback,
                                           void* p_user_data) {
  opj_codec_private_t* l_codec = (opj_codec_private_t*)p_codec;
  if (!l_codec) {
    return OPJ_FALSE;
  }

  l_codec->m_event_mgr.info_handler = p_callback;
  l_codec->m_event_mgr.m_info_data = p_user_data;

  return OPJ_TRUE;
}

OPJ_BOOL OPJ_CALLCONV opj_set_warning_handler(opj_codec_t* p_codec,
                                              opj_msg_callback p_callback,
                                              void* p_user_data) {
  opj_codec_private_t* l_codec = (opj_codec_private_t*)p_codec;
  if (!l_codec) {
    return OPJ_FALSE;
  }

  l_codec->m_event_mgr.warning_handler = p_callback;
  l_codec->m_event_mgr.m_warning_data = p_user_data;

  return OPJ_TRUE;
}

OPJ_BOOL OPJ_CALLCONV opj_set_error_handler(opj_codec_t* p_codec,
                                            opj_msg_callback p_callback,
                                            void* p_user_data) {
  opj_codec_private_t* l_codec = (opj_codec_private_t*)p_codec;
  if (!l_codec) {
    return OPJ_FALSE;
  }

  l_codec->m_event_mgr.error_handler = p_callback;
  l_codec->m_event_mgr.m_error_data = p_user_data;

  return OPJ_TRUE;
}

/* ---------------------------------------------------------------------- */

static OPJ_SIZE_T opj_read_from_file(void* p_buffer, OPJ_SIZE_T p_nb_bytes,
                                     FILE* p_file) {
  OPJ_SIZE_T l_nb_read = fread(p_buffer, 1, p_nb_bytes, p_file);
  return l_nb_read ? l_nb_read : (OPJ_SIZE_T)-1;
}

static OPJ_UINT64 opj_get_data_length_from_file(FILE* p_file) {
  OPJ_OFF_T file_length = 0;

  OPJ_FSEEK(p_file, 0, SEEK_END);
  file_length = (OPJ_UINT64)OPJ_FTELL(p_file);
  OPJ_FSEEK(p_file, 0, SEEK_SET);

  return file_length;
}

static OPJ_SIZE_T opj_write_from_file(void* p_buffer, OPJ_SIZE_T p_nb_bytes,
                                      FILE* p_file) {
  return fwrite(p_buffer, 1, p_nb_bytes, p_file);
}

static OPJ_OFF_T opj_skip_from_file(OPJ_OFF_T p_nb_bytes, FILE* p_user_data) {
  if (OPJ_FSEEK(p_user_data, p_nb_bytes, SEEK_CUR)) {
    return -1;
  }

  return p_nb_bytes;
}

static OPJ_BOOL opj_seek_from_file(OPJ_OFF_T p_nb_bytes, FILE* p_user_data) {
  if (OPJ_FSEEK(p_user_data, p_nb_bytes, SEEK_SET)) {
    return OPJ_FALSE;
  }

  return OPJ_TRUE;
}

/* ---------------------------------------------------------------------- */
#ifdef _WIN32
#ifndef OPJ_STATIC
/*
BOOL APIENTRY
DllMain(HANDLE hModule, DWORD ul_reason_for_call, LPVOID lpReserved) {

  OPJ_ARG_NOT_USED(lpReserved);
  OPJ_ARG_NOT_USED(hModule);

  switch (ul_reason_for_call) {
    case DLL_PROCESS_ATTACH :
      break;
    case DLL_PROCESS_DETACH :
      break;
    case DLL_THREAD_ATTACH :
    case DLL_THREAD_DETACH :
      break;
    }

    return TRUE;
}*/
#endif /* OPJ_STATIC */
#endif /* _WIN32 */

/* ---------------------------------------------------------------------- */

const char* OPJ_CALLCONV opj_version(void) {
  return OPJ_PACKAGE_VERSION;
}

/* ---------------------------------------------------------------------- */
/* DECOMPRESSION FUNCTIONS*/

opj_codec_t* OPJ_CALLCONV opj_create_decompress(OPJ_CODEC_FORMAT p_format) {
  opj_codec_private_t* l_codec = 00;

  l_codec = (opj_codec_private_t*)opj_calloc(1, sizeof(opj_codec_private_t));
  if (!l_codec) {
    return 00;
  }
  memset(l_codec, 0, sizeof(opj_codec_private_t));

  l_codec->is_decompressor = 1;

  switch (p_format) {
    case OPJ_CODEC_J2K:
      l_codec->opj_dump_codec = (void (*)(void*, OPJ_INT32, FILE*))j2k_dump;

      l_codec->opj_get_codec_info =
          (opj_codestream_info_v2_t * (*)(void*)) j2k_get_cstr_info;

      l_codec->opj_get_codec_index =
          (opj_codestream_index_t * (*)(void*)) j2k_get_cstr_index;

      l_codec->m_codec_data.m_decompression.opj_decode =
          (OPJ_BOOL(*)(void*, struct opj_stream_private*, opj_image_t*,
                       struct opj_event_mgr*))opj_j2k_decode;

      l_codec->m_codec_data.m_decompression.opj_end_decompress =
          (OPJ_BOOL(*)(void*, struct opj_stream_private*,
                       struct opj_event_mgr*))opj_j2k_end_decompress;

      l_codec->m_codec_data.m_decompression.opj_read_header =
          (OPJ_BOOL(*)(struct opj_stream_private*, void*, opj_image_t**,
                       struct opj_event_mgr*))opj_j2k_read_header;

      l_codec->m_codec_data.m_decompression.opj_destroy =
          (void (*)(void*))opj_j2k_destroy;

      l_codec->m_codec_data.m_decompression.opj_setup_decoder =
          (void (*)(void*, opj_dparameters_t*))opj_j2k_setup_decoder;

      l_codec->m_codec_data.m_decompression.opj_read_tile_header = (OPJ_BOOL(*)(
          void*, OPJ_UINT32*, OPJ_UINT32*, OPJ_INT32*, OPJ_INT32*, OPJ_INT32*,
          OPJ_INT32*, OPJ_UINT32*, OPJ_BOOL*, struct opj_stream_private*,
          struct opj_event_mgr*))opj_j2k_read_tile_header;

      l_codec->m_codec_data.m_decompression.opj_decode_tile_data = (OPJ_BOOL(*)(
          void*, OPJ_UINT32, OPJ_BYTE*, OPJ_UINT32, struct opj_stream_private*,
          struct opj_event_mgr*))opj_j2k_decode_tile;

      l_codec->m_codec_data.m_decompression.opj_set_decode_area = (OPJ_BOOL(*)(
          void*, opj_image_t*, OPJ_INT32, OPJ_INT32, OPJ_INT32, OPJ_INT32,
          struct opj_event_mgr*))opj_j2k_set_decode_area;

      l_codec->m_codec_data.m_decompression.opj_get_decoded_tile =
          (OPJ_BOOL(*)(void* p_codec, opj_stream_private_t* p_cio,
                       opj_image_t* p_image, struct opj_event_mgr* p_manager,
                       OPJ_UINT32 tile_index))opj_j2k_get_tile;

      l_codec->m_codec_data.m_decompression.opj_set_decoded_resolution_factor =
          (OPJ_BOOL(*)(void* p_codec, OPJ_UINT32 res_factor,
                       struct opj_event_mgr* p_manager))
              opj_j2k_set_decoded_resolution_factor;

      l_codec->m_codec = opj_j2k_create_decompress();

      if (!l_codec->m_codec) {
        opj_free(l_codec);
        return NULL;
      }

      break;

    case OPJ_CODEC_JP2:
      /* get a JP2 decoder handle */
      l_codec->opj_dump_codec = (void (*)(void*, OPJ_INT32, FILE*))jp2_dump;

      l_codec->opj_get_codec_info =
          (opj_codestream_info_v2_t * (*)(void*)) jp2_get_cstr_info;

      l_codec->opj_get_codec_index =
          (opj_codestream_index_t * (*)(void*)) jp2_get_cstr_index;

      l_codec->m_codec_data.m_decompression.opj_decode =
          (OPJ_BOOL(*)(void*, struct opj_stream_private*, opj_image_t*,
                       struct opj_event_mgr*))opj_jp2_decode;

      l_codec->m_codec_data.m_decompression.opj_end_decompress =
          (OPJ_BOOL(*)(void*, struct opj_stream_private*,
                       struct opj_event_mgr*))opj_jp2_end_decompress;

      l_codec->m_codec_data.m_decompression.opj_read_header =
          (OPJ_BOOL(*)(struct opj_stream_private*, void*, opj_image_t**,
                       struct opj_event_mgr*))opj_jp2_read_header;

      l_codec->m_codec_data.m_decompression.opj_read_tile_header = (OPJ_BOOL(*)(
          void*, OPJ_UINT32*, OPJ_UINT32*, OPJ_INT32*, OPJ_INT32*, OPJ_INT32*,
          OPJ_INT32*, OPJ_UINT32*, OPJ_BOOL*, struct opj_stream_private*,
          struct opj_event_mgr*))opj_jp2_read_tile_header;

      l_codec->m_codec_data.m_decompression.opj_decode_tile_data = (OPJ_BOOL(*)(
          void*, OPJ_UINT32, OPJ_BYTE*, OPJ_UINT32, struct opj_stream_private*,
          struct opj_event_mgr*))opj_jp2_decode_tile;

      l_codec->m_codec_data.m_decompression.opj_destroy =
          (void (*)(void*))opj_jp2_destroy;

      l_codec->m_codec_data.m_decompression.opj_setup_decoder =
          (void (*)(void*, opj_dparameters_t*))opj_jp2_setup_decoder;

      l_codec->m_codec_data.m_decompression.opj_set_decode_area = (OPJ_BOOL(*)(
          void*, opj_image_t*, OPJ_INT32, OPJ_INT32, OPJ_INT32, OPJ_INT32,
          struct opj_event_mgr*))opj_jp2_set_decode_area;

      l_codec->m_codec_data.m_decompression.opj_get_decoded_tile =
          (OPJ_BOOL(*)(void* p_codec, opj_stream_private_t* p_cio,
                       opj_image_t* p_image, struct opj_event_mgr* p_manager,
                       OPJ_UINT32 tile_index))opj_jp2_get_tile;

      l_codec->m_codec_data.m_decompression.opj_set_decoded_resolution_factor =
          (OPJ_BOOL(*)(
              void* p_codec, OPJ_UINT32 res_factor,
              opj_event_mgr_t* p_manager))opj_jp2_set_decoded_resolution_factor;

      l_codec->m_codec = opj_jp2_create(OPJ_TRUE);

      if (!l_codec->m_codec) {
        opj_free(l_codec);
        return 00;
      }

      break;
    case OPJ_CODEC_UNKNOWN:
    case OPJ_CODEC_JPT:
    default:
      opj_free(l_codec);
      return 00;
  }

  opj_set_default_event_handler(&(l_codec->m_event_mgr));
  return (opj_codec_t*)l_codec;
}

void OPJ_CALLCONV
opj_set_default_decoder_parameters(opj_dparameters_t* parameters) {
  if (parameters) {
    memset(parameters, 0, sizeof(opj_dparameters_t));
    /* default decoding parameters */
    parameters->cp_layer = 0;
    parameters->cp_reduce = 0;

    parameters->decod_format = -1;
    parameters->cod_format = -1;
    parameters->flags = 0;
/* UniPG>> */
#ifdef USE_JPWL
    parameters->jpwl_correct = OPJ_FALSE;
    parameters->jpwl_exp_comps = JPWL_EXPECTED_COMPONENTS;
    parameters->jpwl_max_tiles = JPWL_MAXIMUM_TILES;
#endif /* USE_JPWL */
       /* <<UniPG */
  }
}

OPJ_BOOL OPJ_CALLCONV opj_setup_decoder(opj_codec_t* p_codec,
                                        opj_dparameters_t* parameters) {
  if (p_codec && parameters) {
    opj_codec_private_t* l_codec = (opj_codec_private_t*)p_codec;

    if (!l_codec->is_decompressor) {
      opj_event_msg(&(l_codec->m_event_mgr), EVT_ERROR,
                    "Codec provided to the opj_setup_decoder function is not a "
                    "decompressor handler.\n");
      return OPJ_FALSE;
    }

    l_codec->m_codec_data.m_decompression.opj_setup_decoder(l_codec->m_codec,
                                                            parameters);
    return OPJ_TRUE;
  }
  return OPJ_FALSE;
}

OPJ_BOOL OPJ_CALLCONV opj_read_header(opj_stream_t* p_stream,
                                      opj_codec_t* p_codec,
                                      opj_image_t** p_image) {
  if (p_codec && p_stream) {
    opj_codec_private_t* l_codec = (opj_codec_private_t*)p_codec;
    opj_stream_private_t* l_stream = (opj_stream_private_t*)p_stream;

    if (!l_codec->is_decompressor) {
      opj_event_msg(&(l_codec->m_event_mgr), EVT_ERROR,
                    "Codec provided to the opj_read_header function is not a "
                    "decompressor handler.\n");
      return OPJ_FALSE;
    }

    return l_codec->m_codec_data.m_decompression.opj_read_header(
        l_stream, l_codec->m_codec, p_image, &(l_codec->m_event_mgr));
  }

  return OPJ_FALSE;
}

OPJ_BOOL OPJ_CALLCONV opj_decode(opj_codec_t* p_codec, opj_stream_t* p_stream,
                                 opj_image_t* p_image) {
  if (p_codec && p_stream) {
    opj_codec_private_t* l_codec = (opj_codec_private_t*)p_codec;
    opj_stream_private_t* l_stream = (opj_stream_private_t*)p_stream;

    if (!l_codec->is_decompressor) {
      return OPJ_FALSE;
    }

    return l_codec->m_codec_data.m_decompression.opj_decode(
        l_codec->m_codec, l_stream, p_image, &(l_codec->m_event_mgr));
  }

  return OPJ_FALSE;
}

OPJ_BOOL OPJ_CALLCONV opj_set_decode_area(
    opj_codec_t* p_codec, opj_image_t* p_image, OPJ_INT32 p_start_x,
    OPJ_INT32 p_start_y, OPJ_INT32 p_end_x, OPJ_INT32 p_end_y) {
  if (p_codec) {
    opj_codec_private_t* l_codec = (opj_codec_private_t*)p_codec;

    if (!l_codec->is_decompressor) {
      return OPJ_FALSE;
    }

    return l_codec->m_codec_data.m_decompression.opj_set_decode_area(
        l_codec->m_codec, p_image, p_start_x, p_start_y, p_end_x, p_end_y,
        &(l_codec->m_event_mgr));
  }
  return OPJ_FALSE;
}

OPJ_BOOL OPJ_CALLCONV opj_read_tile_header(
    opj_codec_t* p_codec, opj_stream_t* p_stream, OPJ_UINT32* p_tile_index,
    OPJ_UINT32* p_data_size, OPJ_INT32* p_tile_x0, OPJ_INT32* p_tile_y0,
    OPJ_INT32* p_tile_x1, OPJ_INT32* p_tile_y1, OPJ_UINT32* p_nb_comps,
    OPJ_BOOL* p_should_go_on) {
  if (p_codec && p_stream && p_data_size && p_tile_index) {
    opj_codec_private_t* l_codec = (opj_codec_private_t*)p_codec;
    opj_stream_private_t* l_stream = (opj_stream_private_t*)p_stream;

    if (!l_codec->is_decompressor) {
      return OPJ_FALSE;
    }

    return l_codec->m_codec_data.m_decompression.opj_read_tile_header(
        l_codec->m_codec, p_tile_index, p_data_size, p_tile_x0, p_tile_y0,
        p_tile_x1, p_tile_y1, p_nb_comps, p_should_go_on, l_stream,
        &(l_codec->m_event_mgr));
  }
  return OPJ_FALSE;
}

OPJ_BOOL OPJ_CALLCONV opj_decode_tile_data(opj_codec_t* p_codec,
                                           OPJ_UINT32 p_tile_index,
                                           OPJ_BYTE* p_data,
                                           OPJ_UINT32 p_data_size,
                                           opj_stream_t* p_stream) {
  if (p_codec && p_data && p_stream) {
    opj_codec_private_t* l_codec = (opj_codec_private_t*)p_codec;
    opj_stream_private_t* l_stream = (opj_stream_private_t*)p_stream;

    if (!l_codec->is_decompressor) {
      return OPJ_FALSE;
    }

    return l_codec->m_codec_data.m_decompression.opj_decode_tile_data(
        l_codec->m_codec, p_tile_index, p_data, p_data_size, l_stream,
        &(l_codec->m_event_mgr));
  }
  return OPJ_FALSE;
}

OPJ_BOOL OPJ_CALLCONV opj_get_decoded_tile(opj_codec_t* p_codec,
                                           opj_stream_t* p_stream,
                                           opj_image_t* p_image,
                                           OPJ_UINT32 tile_index) {
  if (p_codec && p_stream) {
    opj_codec_private_t* l_codec = (opj_codec_private_t*)p_codec;
    opj_stream_private_t* l_stream = (opj_stream_private_t*)p_stream;

    if (!l_codec->is_decompressor) {
      return OPJ_FALSE;
    }

    return l_codec->m_codec_data.m_decompression.opj_get_decoded_tile(
        l_codec->m_codec, l_stream, p_image, &(l_codec->m_event_mgr),
        tile_index);
  }

  return OPJ_FALSE;
}

OPJ_BOOL OPJ_CALLCONV opj_set_decoded_resolution_factor(opj_codec_t* p_codec,
                                                        OPJ_UINT32 res_factor) {
  opj_codec_private_t* l_codec = (opj_codec_private_t*)p_codec;

  if (!l_codec) {
    fprintf(stderr,
            "[ERROR] Input parameters of the setup_decoder function are "
            "incorrect.\n");
    return OPJ_FALSE;
  }

  l_codec->m_codec_data.m_decompression.opj_set_decoded_resolution_factor(
      l_codec->m_codec, res_factor, &(l_codec->m_event_mgr));
  return OPJ_TRUE;
}

/* ---------------------------------------------------------------------- */
/* COMPRESSION FUNCTIONS*/

opj_codec_t* OPJ_CALLCONV opj_create_compress(OPJ_CODEC_FORMAT p_format) {
  opj_codec_private_t* l_codec = 00;

  l_codec = (opj_codec_private_t*)opj_calloc(1, sizeof(opj_codec_private_t));
  if (!l_codec) {
    return 00;
  }
  memset(l_codec, 0, sizeof(opj_codec_private_t));

  l_codec->is_decompressor = 0;

  switch (p_format) {
    case OPJ_CODEC_J2K:
      l_codec->m_codec_data.m_compression.opj_encode =
          (OPJ_BOOL(*)(void*, struct opj_stream_private*,
                       struct opj_event_mgr*))opj_j2k_encode;

      l_codec->m_codec_data.m_compression.opj_end_compress =
          (OPJ_BOOL(*)(void*, struct opj_stream_private*,
                       struct opj_event_mgr*))opj_j2k_end_compress;

      l_codec->m_codec_data.m_compression.opj_start_compress =
          (OPJ_BOOL(*)(void*, struct opj_stream_private*, struct opj_image*,
                       struct opj_event_mgr*))opj_j2k_start_compress;

      l_codec->m_codec_data.m_compression.opj_write_tile = (OPJ_BOOL(*)(
          void*, OPJ_UINT32, OPJ_BYTE*, OPJ_UINT32, struct opj_stream_private*,
          struct opj_event_mgr*))opj_j2k_write_tile;

      l_codec->m_codec_data.m_compression.opj_destroy =
          (void (*)(void*))opj_j2k_destroy;

      l_codec->m_codec_data.m_compression.opj_setup_encoder =
          (void (*)(void*, opj_cparameters_t*, struct opj_image*,
                    struct opj_event_mgr*))opj_j2k_setup_encoder;

      l_codec->m_codec = opj_j2k_create_compress();
      if (!l_codec->m_codec) {
        opj_free(l_codec);
        return 00;
      }

      break;

    case OPJ_CODEC_JP2:
      /* get a JP2 decoder handle */
      l_codec->m_codec_data.m_compression.opj_encode =
          (OPJ_BOOL(*)(void*, struct opj_stream_private*,
                       struct opj_event_mgr*))opj_jp2_encode;

      l_codec->m_codec_data.m_compression.opj_end_compress =
          (OPJ_BOOL(*)(void*, struct opj_stream_private*,
                       struct opj_event_mgr*))opj_jp2_end_compress;

      l_codec->m_codec_data.m_compression.opj_start_compress =
          (OPJ_BOOL(*)(void*, struct opj_stream_private*, struct opj_image*,
                       struct opj_event_mgr*))opj_jp2_start_compress;

      l_codec->m_codec_data.m_compression.opj_write_tile = (OPJ_BOOL(*)(
          void*, OPJ_UINT32, OPJ_BYTE*, OPJ_UINT32, struct opj_stream_private*,
          struct opj_event_mgr*))opj_jp2_write_tile;

      l_codec->m_codec_data.m_compression.opj_destroy =
          (void (*)(void*))opj_jp2_destroy;

      l_codec->m_codec_data.m_compression.opj_setup_encoder =
          (void (*)(void*, opj_cparameters_t*, struct opj_image*,
                    struct opj_event_mgr*))opj_jp2_setup_encoder;

      l_codec->m_codec = opj_jp2_create(OPJ_FALSE);
      if (!l_codec->m_codec) {
        opj_free(l_codec);
        return 00;
      }

      break;

    case OPJ_CODEC_UNKNOWN:
    case OPJ_CODEC_JPT:
    default:
      opj_free(l_codec);
      return 00;
  }

  opj_set_default_event_handler(&(l_codec->m_event_mgr));
  return (opj_codec_t*)l_codec;
}

void OPJ_CALLCONV
opj_set_default_encoder_parameters(opj_cparameters_t* parameters) {
  if (parameters) {
    memset(parameters, 0, sizeof(opj_cparameters_t));
    /* default coding parameters */
    parameters->cp_cinema = OPJ_OFF;
    parameters->max_comp_size = 0;
    parameters->numresolution = 6;
    parameters->cp_rsiz = OPJ_STD_RSIZ;
    parameters->cblockw_init = 64;
    parameters->cblockh_init = 64;
    parameters->prog_order = OPJ_LRCP;
    parameters->roi_compno = -1; /* no ROI */
    parameters->subsampling_dx = 1;
    parameters->subsampling_dy = 1;
    parameters->tp_on = 0;
    parameters->decod_format = -1;
    parameters->cod_format = -1;
    parameters->tcp_rates[0] = 0;
    parameters->tcp_numlayers = 0;
    parameters->cp_disto_alloc = 0;
    parameters->cp_fixed_alloc = 0;
    parameters->cp_fixed_quality = 0;
    parameters->jpip_on = OPJ_FALSE;
/* UniPG>> */
#ifdef USE_JPWL
    parameters->jpwl_epc_on = OPJ_FALSE;
    parameters->jpwl_hprot_MH = -1; /* -1 means unassigned */
    {
      int i;
      for (i = 0; i < JPWL_MAX_NO_TILESPECS; i++) {
        parameters->jpwl_hprot_TPH_tileno[i] = -1; /* unassigned */
        parameters->jpwl_hprot_TPH[i] = 0;         /* absent */
      }
    };
    {
      int i;
      for (i = 0; i < JPWL_MAX_NO_PACKSPECS; i++) {
        parameters->jpwl_pprot_tileno[i] = -1; /* unassigned */
        parameters->jpwl_pprot_packno[i] = -1; /* unassigned */
        parameters->jpwl_pprot[i] = 0;         /* absent */
      }
    };
    parameters->jpwl_sens_size = 0;  /* 0 means no ESD */
    parameters->jpwl_sens_addr = 0;  /* 0 means auto */
    parameters->jpwl_sens_range = 0; /* 0 means packet */
    parameters->jpwl_sens_MH = -1;   /* -1 means unassigned */
    {
      int i;
      for (i = 0; i < JPWL_MAX_NO_TILESPECS; i++) {
        parameters->jpwl_sens_TPH_tileno[i] = -1; /* unassigned */
        parameters->jpwl_sens_TPH[i] = -1;        /* absent */
      }
    };
#endif /* USE_JPWL */
       /* <<UniPG */
  }
}

OPJ_BOOL OPJ_CALLCONV opj_setup_encoder(opj_codec_t* p_codec,
                                        opj_cparameters_t* parameters,
                                        opj_image_t* p_image) {
  if (p_codec && parameters && p_image) {
    opj_codec_private_t* l_codec = (opj_codec_private_t*)p_codec;

    if (!l_codec->is_decompressor) {
      l_codec->m_codec_data.m_compression.opj_setup_encoder(
          l_codec->m_codec, parameters, p_image, &(l_codec->m_event_mgr));
      return OPJ_TRUE;
    }
  }

  return OPJ_FALSE;
}

OPJ_BOOL OPJ_CALLCONV opj_start_compress(opj_codec_t* p_codec,
                                         opj_image_t* p_image,
                                         opj_stream_t* p_stream) {
  if (p_codec && p_stream) {
    opj_codec_private_t* l_codec = (opj_codec_private_t*)p_codec;
    opj_stream_private_t* l_stream = (opj_stream_private_t*)p_stream;

    if (!l_codec->is_decompressor) {
      return l_codec->m_codec_data.m_compression.opj_start_compress(
          l_codec->m_codec, l_stream, p_image, &(l_codec->m_event_mgr));
    }
  }

  return OPJ_FALSE;
}

OPJ_BOOL OPJ_CALLCONV opj_encode(opj_codec_t* p_info, opj_stream_t* p_stream) {
  if (p_info && p_stream) {
    opj_codec_private_t* l_codec = (opj_codec_private_t*)p_info;
    opj_stream_private_t* l_stream = (opj_stream_private_t*)p_stream;

    if (!l_codec->is_decompressor) {
      l_codec->m_codec_data.m_compression.opj_encode(l_codec->m_codec, l_stream,
                                                     &(l_codec->m_event_mgr));
      return OPJ_TRUE;
    }
  }

  return OPJ_FALSE;
}

OPJ_BOOL OPJ_CALLCONV opj_end_compress(opj_codec_t* p_codec,
                                       opj_stream_t* p_stream) {
  if (p_codec && p_stream) {
    opj_codec_private_t* l_codec = (opj_codec_private_t*)p_codec;
    opj_stream_private_t* l_stream = (opj_stream_private_t*)p_stream;

    if (!l_codec->is_decompressor) {
      return l_codec->m_codec_data.m_compression.opj_end_compress(
          l_codec->m_codec, l_stream, &(l_codec->m_event_mgr));
    }
  }
  return OPJ_FALSE;
}

OPJ_BOOL OPJ_CALLCONV opj_end_decompress(opj_codec_t* p_codec,
                                         opj_stream_t* p_stream) {
  if (p_codec && p_stream) {
    opj_codec_private_t* l_codec = (opj_codec_private_t*)p_codec;
    opj_stream_private_t* l_stream = (opj_stream_private_t*)p_stream;

    if (!l_codec->is_decompressor) {
      return OPJ_FALSE;
    }

    return l_codec->m_codec_data.m_decompression.opj_end_decompress(
        l_codec->m_codec, l_stream, &(l_codec->m_event_mgr));
  }

  return OPJ_FALSE;
}

OPJ_BOOL OPJ_CALLCONV opj_set_MCT(opj_cparameters_t* parameters,
                                  OPJ_FLOAT32* pEncodingMatrix,
                                  OPJ_INT32* p_dc_shift, OPJ_UINT32 pNbComp) {
  OPJ_UINT32 l_matrix_size = pNbComp * pNbComp * sizeof(OPJ_FLOAT32);
  OPJ_UINT32 l_dc_shift_size = pNbComp * sizeof(OPJ_INT32);
  OPJ_UINT32 l_mct_total_size = l_matrix_size + l_dc_shift_size;

  /* add MCT capability */
  OPJ_INT32 rsiz = (OPJ_INT32)parameters->cp_rsiz | (OPJ_INT32)OPJ_MCT;
  parameters->cp_rsiz = (OPJ_RSIZ_CAPABILITIES)rsiz;
  parameters->irreversible = 1;

  /* use array based MCT */
  parameters->tcp_mct = 2;
  parameters->mct_data = opj_malloc(l_mct_total_size);
  if (!parameters->mct_data) {
    return OPJ_FALSE;
  }

  memcpy(parameters->mct_data, pEncodingMatrix, l_matrix_size);
  memcpy(((OPJ_BYTE*)parameters->mct_data) + l_matrix_size, p_dc_shift,
         l_dc_shift_size);

  return OPJ_TRUE;
}

OPJ_BOOL OPJ_CALLCONV opj_write_tile(opj_codec_t* p_codec,
                                     OPJ_UINT32 p_tile_index, OPJ_BYTE* p_data,
                                     OPJ_UINT32 p_data_size,
                                     opj_stream_t* p_stream) {
  if (p_codec && p_stream && p_data) {
    opj_codec_private_t* l_codec = (opj_codec_private_t*)p_codec;
    opj_stream_private_t* l_stream = (opj_stream_private_t*)p_stream;

    if (l_codec->is_decompressor) {
      return OPJ_FALSE;
    }

    return l_codec->m_codec_data.m_compression.opj_write_tile(
        l_codec->m_codec, p_tile_index, p_data, p_data_size, l_stream,
        &(l_codec->m_event_mgr));
  }

  return OPJ_FALSE;
}

/* ---------------------------------------------------------------------- */

void OPJ_CALLCONV opj_destroy_codec(opj_codec_t* p_codec) {
  if (p_codec) {
    opj_codec_private_t* l_codec = (opj_codec_private_t*)p_codec;

    if (l_codec->is_decompressor) {
      l_codec->m_codec_data.m_decompression.opj_destroy(l_codec->m_codec);
    } else {
      l_codec->m_codec_data.m_compression.opj_destroy(l_codec->m_codec);
    }

    l_codec->m_codec = 00;
    opj_free(l_codec);
  }
}

/* ---------------------------------------------------------------------- */

void OPJ_CALLCONV opj_dump_codec(opj_codec_t* p_codec, OPJ_INT32 info_flag,
                                 FILE* output_stream) {
  if (p_codec) {
    opj_codec_private_t* l_codec = (opj_codec_private_t*)p_codec;

    l_codec->opj_dump_codec(l_codec->m_codec, info_flag, output_stream);
    return;
  }

  fprintf(
      stderr,
      "[ERROR] Input parameter of the dump_codec function are incorrect.\n");
  return;
}

opj_codestream_info_v2_t* OPJ_CALLCONV opj_get_cstr_info(opj_codec_t* p_codec) {
  if (p_codec) {
    opj_codec_private_t* l_codec = (opj_codec_private_t*)p_codec;

    return l_codec->opj_get_codec_info(l_codec->m_codec);
  }

  return NULL;
}

void OPJ_CALLCONV opj_destroy_cstr_info(opj_codestream_info_v2_t** cstr_info) {
  if (cstr_info) {
    if ((*cstr_info)->m_default_tile_info.tccp_info) {
      opj_free((*cstr_info)->m_default_tile_info.tccp_info);
    }

    if ((*cstr_info)->tile_info) {
      /* FIXME not used for the moment*/
    }

    opj_free((*cstr_info));
    (*cstr_info) = NULL;
  }
}

opj_codestream_index_t* OPJ_CALLCONV opj_get_cstr_index(opj_codec_t* p_codec) {
  if (p_codec) {
    opj_codec_private_t* l_codec = (opj_codec_private_t*)p_codec;

    return l_codec->opj_get_codec_index(l_codec->m_codec);
  }

  return NULL;
}

void OPJ_CALLCONV
opj_destroy_cstr_index(opj_codestream_index_t** p_cstr_index) {
  if (*p_cstr_index) {
    j2k_destroy_cstr_index(*p_cstr_index);
    (*p_cstr_index) = NULL;
  }
}

/* ---------------------------------------------------------------------- */
opj_stream_t* OPJ_CALLCONV
opj_stream_create_default_file_stream(FILE* p_file, OPJ_BOOL p_is_read_stream) {
  return opj_stream_create_file_stream(p_file, OPJ_J2K_STREAM_CHUNK_SIZE,
                                       p_is_read_stream);
}

opj_stream_t* OPJ_CALLCONV opj_stream_create_file_stream(
    FILE* p_file, OPJ_SIZE_T p_size, OPJ_BOOL p_is_read_stream) {
  opj_stream_t* l_stream = 00;

  if (!p_file) {
    return NULL;
  }

  l_stream = opj_stream_create(p_size, p_is_read_stream);
  if (!l_stream) {
    return NULL;
  }

  opj_stream_set_user_data(l_stream, p_file);
  opj_stream_set_user_data_length(l_stream,
                                  opj_get_data_length_from_file(p_file));
  opj_stream_set_read_function(l_stream,
                               (opj_stream_read_fn)opj_read_from_file);
  opj_stream_set_write_function(l_stream,
                                (opj_stream_write_fn)opj_write_from_file);
  opj_stream_set_skip_function(l_stream,
                               (opj_stream_skip_fn)opj_skip_from_file);
  opj_stream_set_seek_function(l_stream,
                               (opj_stream_seek_fn)opj_seek_from_file);

  return l_stream;
}

// FOR ONIS!!!

extern OPJ_UINT32 opj_t2_getnumpasses(opj_bio_t* bio);

extern OPJ_UINT32 opj_t2_getcommacode(opj_bio_t* bio);

extern OPJ_BOOL opj_t2_init_seg(opj_tcd_cblk_dec_t* cblk, OPJ_UINT32 index,
                                OPJ_UINT32 cblksty, OPJ_UINT32 first);

extern OPJ_BOOL opj_t2_skip_packet(opj_t2_t* p_t2, opj_tcd_tile_t* p_tile,
                                   opj_tcp_t* p_tcp, opj_pi_iterator_t* p_pi,
                                   OPJ_BYTE* p_src, OPJ_UINT32* p_data_read,
                                   OPJ_UINT32 p_max_length,
                                   opj_packet_info_t* p_pack_info);

extern void opj_j2k_setup_decoding(opj_j2k_t* p_j2k);

extern OPJ_BOOL opj_j2k_update_image_data(opj_tcd_t* p_tcd, OPJ_BYTE* p_data,
                                          opj_image_t* p_output_image);

extern void opj_j2k_tcp_destroy(opj_tcp_t* p_tcp);

extern void opj_j2k_tcp_data_destroy(opj_tcp_t* p_tcp);

extern OPJ_BOOL opj_t2_read_packet_data(opj_t2_t* p_t2, opj_tcd_tile_t* p_tile,
                                        opj_pi_iterator_t* p_pi,
                                        OPJ_BYTE* p_src_data,
                                        OPJ_UINT32* p_data_read,
                                        OPJ_UINT32 p_max_length,
                                        opj_packet_info_t* pack_info);

typedef struct packet_info {
  OPJ_BYTE* start;
  int size_ph;
  int size_pd;
  int size_total;
  OPJ_UINT32 compno;
  /** resolution that identify the packet */
  OPJ_UINT32 resno;
  /** precinct that identify the packet */
  OPJ_UINT32 precno;
  /** layer that identify the packet */
  OPJ_UINT32 layno;
  /** 0 if the first packet */

} packet_info_t;

OPJ_BOOL get_info_packets(int* dimensions, opj_t2_t* p_t2,
                          opj_tcd_tile_t* p_tile, opj_tcp_t* p_tcp,
                          opj_pi_iterator_t* p_pi, OPJ_BOOL* p_is_data_present,
                          OPJ_BYTE* p_src_data, OPJ_UINT32* p_data_read,
                          OPJ_UINT32 p_max_length,
                          packet_info_t* packet_information)

{
  /* loop */
  OPJ_UINT32 bandno, cblkno;
  OPJ_UINT32 l_nb_code_blocks;
  OPJ_UINT32 l_remaining_length;
  OPJ_UINT32 l_header_length;
  OPJ_UINT32* l_modified_length_ptr = 00;
  OPJ_BYTE* l_current_data = p_src_data;
  opj_cp_t* l_cp = p_t2->cp;
  opj_bio_t* l_bio = 00; /* BIO component */
  opj_tcd_band_t* l_band = 00;
  opj_tcd_cblk_dec_t* l_cblk = 00;
  opj_tcd_resolution_t* l_res =
      &p_tile->comps[p_pi->compno].resolutions[p_pi->resno];
  // pierre
  int size_data_packet = 0;

  dimensions[p_pi->resno * 2] = l_res->x1 - l_res->x0;
  dimensions[p_pi->resno * 2 + 1] = l_res->y1 - l_res->y0;

  OPJ_BYTE* l_header_data = 00;
  OPJ_BYTE** l_header_data_start = 00;

  OPJ_UINT32 l_present;

  packet_information->size_pd = 0;

  if (p_pi->layno == 0) {
    l_band = l_res->bands;

    /* reset tagtrees */
    for (bandno = 0; bandno < l_res->numbands; ++bandno) {
      opj_tcd_precinct_t* l_prc = &l_band->precincts[p_pi->precno];

      if (!((l_band->x1 - l_band->x0 == 0) || (l_band->y1 - l_band->y0 == 0))) {
        opj_tgt_reset(l_prc->incltree);
        opj_tgt_reset(l_prc->imsbtree);
        l_cblk = l_prc->cblks.dec;

        l_nb_code_blocks = l_prc->cw * l_prc->ch;
        for (cblkno = 0; cblkno < l_nb_code_blocks; ++cblkno) {
          l_cblk->numsegs = 0;
          l_cblk->real_num_segs = 0;
          ++l_cblk;
        }
      }

      ++l_band;
    }
  }

  /* SOP markers */

  if (p_tcp->csty & J2K_CP_CSTY_SOP) {
    if ((*l_current_data) != 0xff || (*(l_current_data + 1) != 0x91)) {
      /* TODO opj_event_msg(t2->cinfo->event_mgr, EVT_WARNING, "Expected SOP
       * marker\n"); */
    } else {
      l_current_data += 6;
    }

    /** TODO : check the Nsop value */
  }

  /*
  When the marker PPT/PPM is used the packet header are store in PPT/PPM marker
  This part deal with this caracteristic
  step 1: Read packet header in the saved structure
  step 2: Return to codestream for decoding
  */

  l_bio = opj_bio_create();
  if (!l_bio) {
    return OPJ_FALSE;
  }

  if (l_cp->ppm == 1) { /* PPM */
    l_header_data_start = &l_cp->ppm_data;
    l_header_data = *l_header_data_start;
    l_modified_length_ptr = &(l_cp->ppm_len);

  } else if (p_tcp->ppt == 1) { /* PPT */
    l_header_data_start = &(p_tcp->ppt_data);
    l_header_data = *l_header_data_start;
    l_modified_length_ptr = &(p_tcp->ppt_len);
  } else { /* Normal Case */
    l_header_data_start = &(l_current_data);
    l_header_data = *l_header_data_start;
    l_remaining_length = OPJ_UINT32(p_src_data + p_max_length - l_header_data);
    l_modified_length_ptr = &(l_remaining_length);
  }

  opj_bio_init_dec(l_bio, l_header_data, *l_modified_length_ptr);

  l_present = opj_bio_read(l_bio, 1);
  if (!l_present) {
    /* TODO MSD: no test to control the output of this function*/
    opj_bio_inalign(l_bio);
    l_header_data += opj_bio_numbytes(l_bio);
    opj_bio_destroy(l_bio);

    /* EPH markers */
    if (p_tcp->csty & J2K_CP_CSTY_EPH) {
      if ((*l_header_data) != 0xff || (*(l_header_data + 1) != 0x92)) {
        printf("Error : expected EPH marker\n");
      } else {
        l_header_data += 2;
      }
    }

    l_header_length = OPJ_UINT32((l_header_data - *l_header_data_start));
    *l_modified_length_ptr -= l_header_length;
    *l_header_data_start += l_header_length;

    /* << INDEX */
    /* End of packet header position. Currently only represents the distance to
    start of packet Will be updated later by incrementing with packet start
    value */

    /* INDEX >> */

    *p_is_data_present = OPJ_FALSE;
    *p_data_read = OPJ_UINT32(l_current_data - p_src_data);
    return OPJ_TRUE;
  }

  l_band = l_res->bands;
  for (bandno = 0; bandno < l_res->numbands; ++bandno) {
    opj_tcd_precinct_t* l_prc = &(l_band->precincts[p_pi->precno]);

    if ((l_band->x1 - l_band->x0 == 0) || (l_band->y1 - l_band->y0 == 0)) {
      ++l_band;
      continue;
    }

    l_nb_code_blocks = l_prc->cw * l_prc->ch;
    l_cblk = l_prc->cblks.dec;
    for (cblkno = 0; cblkno < l_nb_code_blocks; cblkno++) {
      OPJ_UINT32 l_included, l_increment, l_segno;
      OPJ_INT32 n;

      /* if cblk not yet included before --> inclusion tagtree */
      if (!l_cblk->numsegs) {
        l_included =
            opj_tgt_decode(l_bio, l_prc->incltree, cblkno, p_pi->layno + 1);
        /* else one bit */
      } else {
        l_included = opj_bio_read(l_bio, 1);
      }

      /* if cblk not included */
      if (!l_included) {
        l_cblk->numnewpasses = 0;
        ++l_cblk;
        continue;
      }

      /* if cblk not yet included --> zero-bitplane tagtree */
      if (!l_cblk->numsegs) {
        OPJ_UINT32 i = 0;

        while (!opj_tgt_decode(l_bio, l_prc->imsbtree, cblkno, i)) {
          ++i;
        }

        l_cblk->numbps = l_band->numbps + 1 - i;
        l_cblk->numlenbits = 3;
      }

      /* number of coding passes */
      l_cblk->numnewpasses = opj_t2_getnumpasses(l_bio);
      l_increment = opj_t2_getcommacode(l_bio);

      /* length indicator increment */
      l_cblk->numlenbits += l_increment;
      l_segno = 0;

      if (!l_cblk->numsegs) {
        if (!opj_t2_init_seg(l_cblk, l_segno,
                             p_tcp->tccps[p_pi->compno].cblksty, 1)) {
          opj_bio_destroy(l_bio);
          return OPJ_FALSE;
        }
      } else {
        l_segno = l_cblk->numsegs - 1;
        if (l_cblk->segs[l_segno].numpasses ==
            l_cblk->segs[l_segno].maxpasses) {
          ++l_segno;
          if (!opj_t2_init_seg(l_cblk, l_segno,
                               p_tcp->tccps[p_pi->compno].cblksty, 0)) {
            opj_bio_destroy(l_bio);
            return OPJ_FALSE;
          }
        }
      }
      n = l_cblk->numnewpasses;

      do {
        l_cblk->segs[l_segno].numnewpasses = opj_int_min(
            l_cblk->segs[l_segno].maxpasses - l_cblk->segs[l_segno].numpasses,
            n);
        l_cblk->segs[l_segno].newlen = opj_bio_read(
            l_bio, l_cblk->numlenbits +
                       opj_uint_floorlog2(l_cblk->segs[l_segno].numnewpasses));

        size_data_packet += l_cblk->segs[l_segno].newlen;
        n -= l_cblk->segs[l_segno].numnewpasses;
        if (n > 0) {
          ++l_segno;

          if (!opj_t2_init_seg(l_cblk, l_segno,
                               p_tcp->tccps[p_pi->compno].cblksty, 0)) {
            opj_bio_destroy(l_bio);
            return OPJ_FALSE;
          }
        }
      } while (n > 0);

      ++l_cblk;
    }

    ++l_band;
  }

  if (!opj_bio_inalign(l_bio)) {
    opj_bio_destroy(l_bio);
    return OPJ_FALSE;
  }

  l_header_data += opj_bio_numbytes(l_bio);
  opj_bio_destroy(l_bio);

  /* EPH markers */
  if (p_tcp->csty & J2K_CP_CSTY_EPH) {
    if ((*l_header_data) != 0xff || (*(l_header_data + 1) != 0x92)) {
      /* TODO opj_event_msg(t2->cinfo->event_mgr, EVT_ERROR, "Expected EPH
       * marker\n"); */
    } else {
      l_header_data += 2;
    }
  }

  l_header_length = OPJ_UINT32((l_header_data - *l_header_data_start));
  *l_modified_length_ptr -= l_header_length;
  *l_header_data_start += l_header_length;

  /* << INDEX */
  /* End of packet header position. Currently only represents the distance to
  start of packet Will be updated later by incrementing with packet start value
*/
  /* INDEX >> */

  *p_is_data_present = OPJ_TRUE;
  *p_data_read = OPJ_UINT32(l_current_data - p_src_data);
  packet_information->size_pd = size_data_packet;
  return OPJ_TRUE;
}

OPJ_BOOL find_layer_res_10(int* dimensions, opj_t2_t* p_t2,
                           opj_tcd_tile_t* p_tile, opj_tcp_t* p_tcp,
                           opj_pi_iterator_t* p_pi, OPJ_BYTE* p_src,
                           OPJ_UINT32* p_data_read, OPJ_UINT32 p_max_length,
                           opj_packet_info_t* p_pack_info,
                           packet_info_t* packet_information,
                           bool* can_continue) {
  OPJ_BOOL l_read_data;
  OPJ_UINT32 l_nb_bytes_read = 0;
  OPJ_UINT32 l_nb_total_bytes_read = 0;
  int p_max_length_copie = (int)p_max_length;

  *p_data_read = 0;

  packet_information->start = p_src;
  packet_information->compno = p_pi->compno;
  packet_information->resno = p_pi->resno;
  packet_information->precno = p_pi->precno;
  packet_information->layno = p_pi->layno;

  if (!get_info_packets(dimensions, p_t2, p_tile, p_tcp, p_pi, &l_read_data,
                        p_src, &l_nb_bytes_read, p_max_length,
                        packet_information)) {
    return OPJ_FALSE;
  }
  packet_information->size_ph = l_nb_bytes_read;
  packet_information->size_total =
      packet_information->size_ph + packet_information->size_pd;

  p_src += l_nb_bytes_read;
  l_nb_total_bytes_read += l_nb_bytes_read;
  p_max_length_copie -= packet_information->size_total;

  if (p_max_length_copie <= 0) {
    (*can_continue) = false;
    return OPJ_TRUE;
  }
  ////////////////////////////////////////
  // REVOIR CETTE PARTIE LA : FICHIER TEMP.CPP
  ////////////////////////////////////////

  /* we should read data for the packet */

  if (l_read_data) {
    l_nb_bytes_read = 0;

    if (!opj_t2_read_packet_data(p_t2, p_tile, p_pi, p_src, &l_nb_bytes_read,
                                 p_max_length, p_pack_info)) {
      // return OPJ_FALSE;
    }

    l_nb_total_bytes_read += l_nb_bytes_read;
  }

  // l_nb_total_bytes_read += packet_information->size_pd;

  // l_nb_total_bytes_read += l_nb_bytes_read;

  *p_data_read = l_nb_total_bytes_read;

  return OPJ_TRUE;
}

OPJ_BOOL find_layer_res_9(int* dimensions, opj_t2_t* p_t2, OPJ_UINT32 p_tile_no,
                          opj_tcd_tile_t* p_tile, OPJ_BYTE* p_src,
                          OPJ_UINT32* p_data_read, OPJ_UINT32 p_max_len,
                          opj_codestream_index_t* p_cstr_index,
                          packet_info_t** tab_packets) {
  int packet_index = 0;
  OPJ_BYTE* l_current_data = p_src;
  opj_pi_iterator_t* l_pi = 00;
  OPJ_UINT32 pino;
  opj_image_t* l_image = p_t2->image;
  opj_cp_t* l_cp = p_t2->cp;
  opj_tcp_t* l_tcp = &(p_t2->cp->tcps[p_tile_no]);
  OPJ_UINT32 l_nb_bytes_read;
  OPJ_UINT32 l_nb_pocs = l_tcp->numpocs + 1;
  opj_pi_iterator_t* l_current_pi = 00;
  bool can_continue = true;
#ifdef TODO_MSD
  OPJ_UINT32 curtp = 0;
  OPJ_UINT32 tp_start_packno;
#endif
  opj_packet_info_t* l_pack_info = 00;
  opj_image_comp_t* l_img_comp = 00;
  OPJ_ARG_NOT_USED(p_cstr_index);

#ifdef TODO_MSD
  if (p_cstr_index) {
    l_pack_info = p_cstr_index->tile_index[p_tile_no].packet;
  }
#endif

  /* create a packet iterator */
  l_pi = opj_pi_create_decode(l_image, l_cp, p_tile_no);
  if (!l_pi) {
    return OPJ_FALSE;
  }

  l_current_pi = l_pi;

  for (pino = 0; pino <= l_tcp->numpocs; ++pino) {
    /* if the resolution needed is to low, one dim of the tilec could be equal
     * to zero and no packets are used to encode this resolution and
     * l_current_pi->resno is always >=
     * p_tile->comps[l_current_pi->compno].minimum_num_resolutions and no
     * l_img_comp->resno_decoded are computed
     */
    OPJ_BOOL* first_pass_failed =
        (OPJ_BOOL*)opj_malloc(l_image->numcomps * sizeof(OPJ_BOOL));
    if (!first_pass_failed) {
      opj_pi_destroy(l_pi, l_nb_pocs);
      return OPJ_FALSE;
    }
    memset(first_pass_failed, OPJ_TRUE, l_image->numcomps * sizeof(OPJ_BOOL));

    while (opj_pi_next(l_current_pi)) {
      if (can_continue) {
        l_nb_bytes_read = 0;

        first_pass_failed[l_current_pi->compno] = OPJ_FALSE;
        // pierre
        // p_cstr_index->tile_index[p_tile_no].packet_index[p_cstr_index->tile_index->nb_packet].disto
        // = 0;
        // p_cstr_index->tile_index[p_tile_no].packet_index[p_cstr_index->tile_index->nb_packet].end_ph_pos
        // = 0;
        // p_cstr_index->tile_index[p_tile_no].packet_index[p_cstr_index->tile_index->nb_packet].end_pos
        // = 0;
        // p_cstr_index->tile_index[p_tile_no].packet_index[p_cstr_index->tile_index->nb_packet].start_pos
        // = 0; l_pack_info =
        // &p_cstr_index->tile_index[p_tile_no].packet_index[p_cstr_index->tile_index->nb_packet];

        packet_info_t* packet_information = new packet_info_t;

        if (!find_layer_res_10(dimensions, p_t2, p_tile, l_tcp, l_current_pi,
                               l_current_data, &l_nb_bytes_read, p_max_len,
                               l_pack_info, packet_information,
                               &can_continue)) {
          delete packet_information;
          opj_pi_destroy(l_pi, l_nb_pocs);
          opj_free(first_pass_failed);
          return OPJ_FALSE;
        }

        if (!can_continue) {
          delete packet_information;
          break;
        }

        l_current_data += l_nb_bytes_read;
        p_max_len -= l_nb_bytes_read;

        tab_packets[packet_index] = packet_information;
        packet_index++;

        // pierre
        // p_cstr_index->tile_index->nb_packet++;
        l_img_comp = &(l_image->comps[l_current_pi->compno]);
        l_img_comp->resno_decoded =
            opj_uint_max(l_current_pi->resno, l_img_comp->resno_decoded);
      }
      /*else {
      l_nb_bytes_read = 0;
      if (!
      opj_t2_skip_packet(p_t2,p_tile,l_tcp,l_current_pi,l_current_data,&l_nb_bytes_read,p_max_len,l_pack_info))
      { opj_pi_destroy(l_pi,l_nb_pocs); opj_free(first_pass_failed);
      //return OPJ_FALSE;
      return OPJ_TRUE;
      }
      }*/

      if (first_pass_failed[l_current_pi->compno]) {
        l_img_comp = &(l_image->comps[l_current_pi->compno]);
        if (l_img_comp->resno_decoded == 0)
          l_img_comp->resno_decoded =
              p_tile->comps[l_current_pi->compno].minimum_num_resolutions - 1;
      }

      /* INDEX >> */
#ifdef TODO_MSD
      if (p_cstr_info) {
        opj_tile_info_v2_t* info_TL = &p_cstr_info->tile[p_tile_no];
        opj_packet_info_t* info_PK = &info_TL->packet[p_cstr_info->packno];
        tp_start_packno = 0;
        if (!p_cstr_info->packno) {
          info_PK->start_pos = info_TL->end_header + 1;
        } else if (info_TL->packet[p_cstr_info->packno - 1].end_pos >=
                   (OPJ_INT32)p_cstr_info->tile[p_tile_no]
                       .tp[curtp]
                       .tp_end_pos) { /* New tile part */
          info_TL->tp[curtp].tp_numpacks =
              p_cstr_info->packno -
              tp_start_packno; /* Number of packets in previous tile-part */
          tp_start_packno = p_cstr_info->packno;
          curtp++;
          info_PK->start_pos =
              p_cstr_info->tile[p_tile_no].tp[curtp].tp_end_header + 1;
        } else {
          info_PK->start_pos =
              (l_cp->m_specific_param.m_enc.m_tp_on && info_PK->start_pos)
                  ? info_PK->start_pos
                  : info_TL->packet[p_cstr_info->packno - 1].end_pos + 1;
        }
        info_PK->end_pos = info_PK->start_pos + l_nb_bytes_read - 1;
        info_PK->end_ph_pos +=
            info_PK->start_pos -
            1; /* End of packet header which now only represents the distance */
        ++p_cstr_info->packno;
      }
#endif
      /* << INDEX */
    }
    ++l_current_pi;

    opj_free(first_pass_failed);
  }
  /* INDEX >> */
#ifdef TODO_MSD
  if (p_cstr_info) {
    p_cstr_info->tile[p_tile_no].tp[curtp].tp_numpacks =
        p_cstr_info->packno -
        tp_start_packno; /* Number of packets in last tile-part */
  }
#endif
  /* << INDEX */

  /* don't forget to release pi */
  opj_pi_destroy(l_pi, l_nb_pocs);
  *p_data_read = OPJ_UINT32(l_current_data - p_src);
  return OPJ_TRUE;
}

OPJ_BOOL find_layer_res_8(int** tab, int** dimensions, int res,
                          int sample_pixel, opj_tcd_t* p_tcd,
                          OPJ_BYTE* p_src_data, OPJ_UINT32* p_data_read,
                          OPJ_UINT32 p_max_src_size,
                          opj_codestream_index_t* p_cstr_index,
                          opj_dparameters_t* parameterspointeur) {
  opj_t2_t* l_t2;
  int iterator_ret_tab = 0;
  int size_tab_packets = res * parameterspointeur->cp_layer * sample_pixel;
  packet_info_t** tab_packets = new packet_info_t*[size_tab_packets];

  int size1 = res * parameterspointeur->cp_layer;
  *tab = new int[res * parameterspointeur->cp_layer];
  *dimensions = new int[res * 2];
  memset(*dimensions, 0, res * 2 * sizeof(int));
  int packet_iterator;

  int sum_packet_size = int(p_cstr_index->tile_index->tp_index->end_header + 2);

  memset(tab_packets, 0, size_tab_packets * sizeof(packet_info_t*));
  memset(*tab, 0, res * parameterspointeur->cp_layer * sizeof(int));
  l_t2 = opj_t2_create(p_tcd->image, p_tcd->cp);
  if (l_t2 == 00) {
    return OPJ_FALSE;
  }

  if (!find_layer_res_9(*dimensions, l_t2, p_tcd->tcd_tileno,
                        p_tcd->tcd_image->tiles, p_src_data, p_data_read,
                        p_max_src_size, p_cstr_index, tab_packets)) {
    opj_t2_destroy(l_t2);
    return OPJ_FALSE;
  }
  // on determine les layout resolution que l'on veux decode

  if (sample_pixel == 1) {
    for (packet_iterator = 0; packet_iterator < size_tab_packets - 1;
         packet_iterator++) {
      sum_packet_size += tab_packets[packet_iterator]->size_total;
      (*tab)[packet_iterator] = sum_packet_size;
    }
  }
  if (sample_pixel == 3) {
    for (packet_iterator = 0, iterator_ret_tab = 0;
         packet_iterator < size_tab_packets - 1; packet_iterator++) {
      sum_packet_size += tab_packets[packet_iterator]->size_total;

      if (tab_packets[packet_iterator]->compno == 2) {
        (*tab)[iterator_ret_tab] = sum_packet_size;
        iterator_ret_tab++;
      }
    }
  }

  /*---------------CLEAN-------------------*/
  if (tab_packets != NULL) {
    for (int i = 0; i < size_tab_packets; i++)
      if (tab_packets[i] != NULL)
        delete tab_packets[i];
    delete[] tab_packets;
  }
  opj_t2_destroy(l_t2);
  return OPJ_TRUE;
}

OPJ_BOOL find_layer_res_7(int** tab, int** dimensions, int res,
                          int sample_pixel, opj_tcd_t* p_tcd, OPJ_BYTE* p_src,
                          OPJ_UINT32 p_max_length, OPJ_UINT32 p_tile_no,
                          opj_codestream_index_t* p_cstr_index,
                          opj_dparameters_t* parameterspointeur) {
  OPJ_UINT32 l_data_read;

  // declaration Pierre

  // opj_tcd_t pierre_data_p_tcd = (*p_tcd);
  // opj_tcd_t * pierre_p_tcd = &pierre_data_p_tcd;
  // OPJ_BYTE *pierre_p_src = p_src;
  // opj_codestream_index_t pierre_data_p_cstr_index = (*p_cstr_index);
  // opj_codestream_index_t *pierre_p_cstr_index = &pierre_data_p_cstr_index;

  // OPJ_UINT32 pierre_p_max_length = p_max_length;

  p_tcd->tcd_tileno = p_tile_no;

  p_tcd->tcp = &(p_tcd->cp->tcps[p_tile_no]);

#ifdef TODO_MSD /* FIXME */
  /* INDEX >>  */
  if (p_cstr_info) {
    OPJ_UINT32 resno, compno, numprec = 0;
    for (compno = 0; compno < (OPJ_UINT32)p_cstr_info->numcomps; compno++) {
      opj_tcp_t* tcp = &p_tcd->cp->tcps[0];
      opj_tccp_t* tccp = &tcp->tccps[compno];
      opj_tcd_tilecomp_t* tilec_idx = &p_tcd->tcd_image->tiles->comps[compno];
      for (resno = 0; resno < tilec_idx->numresolutions; resno++) {
        opj_tcd_resolution_t* res_idx = &tilec_idx->resolutions[resno];
        p_cstr_info->tile[p_tile_no].pw[resno] = res_idx->pw;
        p_cstr_info->tile[p_tile_no].ph[resno] = res_idx->ph;
        numprec += res_idx->pw * res_idx->ph;
        p_cstr_info->tile[p_tile_no].pdx[resno] = tccp->prcw[resno];
        p_cstr_info->tile[p_tile_no].pdy[resno] = tccp->prch[resno];
      }
    }
    p_cstr_info->tile[p_tile_no].packet = (opj_packet_info_t*)opj_malloc(
        p_cstr_info->numlayers * numprec * sizeof(opj_packet_info_t));
    p_cstr_info->packno = 0;
  }
  /* << INDEX */
#endif
  // pierre
  /*--------------Calcul_Layer_res_max------------------*/

  // p_max_length = (int)p_max_length/10;
  // p_max_length = 130000;
  l_data_read = 0;
  if (!find_layer_res_8(tab, dimensions, res, sample_pixel, p_tcd, p_src,
                        &l_data_read, p_max_length, p_cstr_index,
                        parameterspointeur)) {
    return OPJ_FALSE;
  }
  return OPJ_TRUE;
}

OPJ_BOOL find_layer_res_6(int** tab, int** dimensions, int res,
                          int sample_pixel, opj_j2k_t* p_j2k,
                          OPJ_UINT32 p_tile_index, OPJ_BYTE* p_data,
                          OPJ_UINT32 p_data_size,
                          opj_stream_private_t* p_stream,
                          opj_event_mgr_t* p_manager,
                          opj_dparameters_t* parameterspointeur) {
  OPJ_UINT32 l_current_marker;
  OPJ_BYTE l_data[2];
  opj_tcp_t* l_tcp;

  /* preconditions */
  assert(p_stream != 00);
  assert(p_j2k != 00);
  assert(p_manager != 00);

  if (!(p_j2k->m_specific_param.m_decoder.m_state &
        0x0080 /*FIXME J2K_DEC_STATE_DATA*/) ||
      (p_tile_index != p_j2k->m_current_tile_number)) {
    return OPJ_FALSE;
  }

  l_tcp = &(p_j2k->m_cp.tcps[p_tile_index]);
  if (!l_tcp->m_data) {
    opj_j2k_tcp_destroy(l_tcp);
    return OPJ_FALSE;
  }

  if (!find_layer_res_7(tab, dimensions, res, sample_pixel, p_j2k->m_tcd,
                        l_tcp->m_data, l_tcp->m_data_size, p_tile_index,
                        p_j2k->cstr_index, parameterspointeur)) {
    opj_j2k_tcp_destroy(l_tcp);
    p_j2k->m_specific_param.m_decoder.m_state |=
        0x8000; /*FIXME J2K_DEC_STATE_ERR;*/
    return OPJ_FALSE;
  }

  if (!opj_tcd_update_tile_data(p_j2k->m_tcd, p_data, p_data_size)) {
    return OPJ_FALSE;
  }

  /* To avoid to destroy the tcp which can be useful when we try to decode a
   * tile decoded before (cf j2k_random_tile_access) we destroy just the data
   * which will be re-read in read_tile_header*/
  /*opj_j2k_tcp_destroy(l_tcp);
  p_j2k->m_tcd->tcp = 0;*/
  opj_j2k_tcp_data_destroy(l_tcp);

  p_j2k->m_specific_param.m_decoder.m_can_decode = 0;
  p_j2k->m_specific_param.m_decoder.m_state &=
      (~(0x0080)); /* FIXME J2K_DEC_STATE_DATA);*/

  if (p_j2k->m_specific_param.m_decoder.m_state !=
      0x0100) { /*FIXME J2K_DEC_STATE_EOC)*/
    if (opj_stream_read_data(p_stream, l_data, 2, p_manager) != 2) {
      opj_event_msg(p_manager, EVT_ERROR, "Stream too short\n");
      return OPJ_FALSE;
    }

    opj_read_bytes(l_data, &l_current_marker, 2);

    if (l_current_marker == J2K_MS_EOC) {
      p_j2k->m_current_tile_number = 0;
      p_j2k->m_specific_param.m_decoder.m_state =
          0x0100; /*FIXME J2K_DEC_STATE_EOC;*/
    } else if (l_current_marker != J2K_MS_SOT) {
      opj_event_msg(p_manager, EVT_ERROR, "Stream too short, expected SOT\n");
      return OPJ_FALSE;
    }
  }

  return OPJ_TRUE;
}

OPJ_BOOL find_layer_res_5(int** tab, int** dimensions, int res,
                          int sample_pixel, opj_j2k_t* p_j2k,
                          opj_stream_private_t* p_stream,
                          opj_event_mgr_t* p_manager,
                          opj_dparameters_t* parameterspointeur) {
  OPJ_BOOL l_go_on = OPJ_TRUE;
  OPJ_UINT32 l_current_tile_no;
  OPJ_UINT32 l_data_size, l_max_data_size;
  OPJ_INT32 l_tile_x0, l_tile_y0, l_tile_x1, l_tile_y1;
  OPJ_UINT32 l_nb_comps;
  OPJ_BYTE* l_current_data;

  l_current_data = (OPJ_BYTE*)opj_malloc(1000);
  if (!l_current_data) {
    opj_event_msg(p_manager, EVT_ERROR, "Not enough memory to decode tiles\n");
    return OPJ_FALSE;
  }
  l_max_data_size = 1000;

  while (OPJ_TRUE) {
    if (!opj_j2k_read_tile_header(p_j2k, &l_current_tile_no, &l_data_size,
                                  &l_tile_x0, &l_tile_y0, &l_tile_x1,
                                  &l_tile_y1, &l_nb_comps, &l_go_on, p_stream,
                                  p_manager)) {
      opj_free(l_current_data);
      return OPJ_FALSE;
    }

    if (!l_go_on) {
      break;
    }

    if (l_data_size > l_max_data_size) {
      OPJ_BYTE* l_new_current_data =
          (OPJ_BYTE*)opj_realloc(l_current_data, l_data_size);
      if (!l_new_current_data) {
        opj_free(l_current_data);
        opj_event_msg(p_manager, EVT_ERROR,
                      "Not enough memory to decode tile %d/%d\n",
                      l_current_tile_no + 1, p_j2k->m_cp.th * p_j2k->m_cp.tw);
        return OPJ_FALSE;
      }
      l_current_data = l_new_current_data;
      l_max_data_size = l_data_size;
    }

    if (!find_layer_res_6(tab, dimensions, res, sample_pixel, p_j2k,
                          l_current_tile_no, l_current_data, l_data_size,
                          p_stream, p_manager, parameterspointeur)) {
      opj_free(l_current_data);
      return OPJ_FALSE;
    }
    /*
    opj_event_msg(p_manager, EVT_INFO, "Tile %d/%d has been decoded.\n",
    l_current_tile_no +1, p_j2k->m_cp.th * p_j2k->m_cp.tw);

    if (! opj_j2k_update_image_data(p_j2k->m_tcd,l_current_data,
    p_j2k->m_output_image)) { opj_free(l_current_data); return OPJ_FALSE;
    }
    opj_event_msg(p_manager, EVT_INFO, "Image data has been updated with tile
    %d.\n\n", l_current_tile_no + 1);
    */
  }

  opj_free(l_current_data);

  return OPJ_TRUE;
}

OPJ_BOOL find_layer_res_4(int** tab, int** dimensions, int res,
                          int sample_pixel, opj_j2k_t* p_j2k,
                          opj_procedure_list_t* p_procedure_list,
                          opj_stream_private_t* p_stream,
                          opj_event_mgr_t* p_manager,
                          opj_dparameters_t* parameterspointeur) {
  OPJ_BOOL (**l_procedure)(opj_j2k_t*, opj_stream_private_t*,
                           opj_event_mgr_t*) = 00;
  OPJ_BOOL l_result = OPJ_TRUE;
  OPJ_UINT32 l_nb_proc, i;

  /* preconditions*/
  assert(p_procedure_list != 00);
  assert(p_j2k != 00);
  assert(p_stream != 00);
  assert(p_manager != 00);

  l_nb_proc = opj_procedure_list_get_nb_procedures(p_procedure_list);
  l_procedure =
      (OPJ_BOOL(**)(opj_j2k_t*, opj_stream_private_t*, opj_event_mgr_t*))
          opj_procedure_list_get_first_procedure(p_procedure_list);

  for (i = 0; i < l_nb_proc; ++i) {
    l_result =
        l_result && find_layer_res_5(tab, dimensions, res, sample_pixel, p_j2k,
                                     p_stream, p_manager, parameterspointeur);
    ++l_procedure;
  }

  /* and clear the procedure list at the end.*/
  opj_procedure_list_clear(p_procedure_list);
  return l_result;
}

OPJ_BOOL find_layer_res_3(int** tab, int** dimensions, int res,
                          int sample_pixel, opj_j2k_t* p_j2k,
                          opj_stream_private_t* p_stream, opj_image_t* p_image,
                          opj_event_mgr_t* p_manager,
                          opj_dparameters_t* parameterspointeur) {
  if (!p_image)
    return OPJ_FALSE;

  p_j2k->m_output_image = opj_image_create0();
  if (!(p_j2k->m_output_image)) {
    return OPJ_FALSE;
  }
  opj_copy_image_header(p_image, p_j2k->m_output_image);

  /* customization of the decoding */
  opj_j2k_setup_decoding(p_j2k);

  /* Decode the codestream */
  if (!find_layer_res_4(tab, dimensions, res, sample_pixel, p_j2k,
                        p_j2k->m_procedure_list, p_stream, p_manager,
                        parameterspointeur)) {
    opj_image_destroy(p_j2k->m_private_image);
    p_j2k->m_private_image = NULL;
    return OPJ_FALSE;
  }

  /* Move data and copy one information from codec to output image*/
  /*
  for (compno = 0; compno < p_image->numcomps; compno++) {
  p_image->comps[compno].resno_decoded =
  p_j2k->m_output_image->comps[compno].resno_decoded;
  p_image->comps[compno].data = p_j2k->m_output_image->comps[compno].data;
  p_j2k->m_output_image->comps[compno].data = NULL;
  }*/

  return OPJ_TRUE;
}

OPJ_BOOL find_layer_res_2(int** tab, int** dimensions, int res,
                          int sample_pixel, opj_j2k_t* j2k,
                          opj_stream_private_t* p_stream, opj_image_t* p_image,
                          opj_event_mgr_t* p_manager,
                          opj_dparameters_t* parameterspointeur) {
  if (!p_image)
    return OPJ_FALSE;

  /* J2K decoding */
  if (!find_layer_res_3(tab, dimensions, res, sample_pixel, j2k, p_stream,
                        p_image, p_manager, parameterspointeur)) {
    opj_event_msg(p_manager, EVT_ERROR,
                  "Failed to decode the codestream in the JP2 file\n");
    return OPJ_FALSE;
  }
  return OPJ_TRUE;
}

OPJ_BOOL find_layer_res_1(int** tab, int** dimensions, int res,
                          int sample_pixel, opj_codec_t* p_codec,
                          opj_stream_t* p_stream, opj_image_t* p_image,
                          opj_dparameters_t* parameterspointeur) {
  if (p_codec && p_stream) {
    opj_codec_private_t* l_codec = (opj_codec_private_t*)p_codec;
    opj_stream_private_t* l_stream = (opj_stream_private_t*)p_stream;

    if (!l_codec->is_decompressor) {
      return OPJ_FALSE;
    }

    return find_layer_res_2(tab, dimensions, res, sample_pixel,
                            (opj_j2k_t*)l_codec->m_codec, l_stream, p_image,
                            &(l_codec->m_event_mgr), parameterspointeur);
  }
  return OPJ_FALSE;
}
