
#include "dcmtk/dcmjpeg/djdijg2k.h"
#include "dcmtk/config/osconfig.h"
#include "dcmtk/dcmdata/dcerror.h"
#include "dcmtk/dcmjpeg/djcparam.h"
#include "dcmtk/dcmjpeg/opjbufferdata.h"
#include "dcmtk/ofstd/ofconsol.h"

#define INCLUDE_CSTDIO
#define INCLUDE_CSETJMP
#include "dcmtk/ofstd/ofstdinc.h"

#ifdef HAVE_STDLIB_H
#undef HAVE_STDLIB_H
#endif
#ifdef HAVE_STDDEF_H
#undef HAVE_STDDEF_H
#endif

BEGIN_EXTERN_C
#define boolean ijg_boolean
#undef boolean

#ifdef const
#undef const
#endif

#include "openjpeg.h"

#define J2K_CFMT 0
#define JP2_CFMT 1
#define JPT_CFMT 2
#define MJ2_CFMT 3
#define PXM_DFMT 0
#define PGX_DFMT 1
#define BMP_DFMT 2
#define YUV_DFMT 3

using namespace std;

static void error_callback(const char* msg, void* a) {
  ofConsole.lockCerr() << "JPEG2000 error  : " << msg << endl;
  ofConsole.unlockCerr();
}
static void warning_callback(const char* msg, void* a) {
  ofConsole.lockCerr() << "JPEG2000 warning  : " << msg << endl;
  ofConsole.unlockCerr();
}

static void info_callback(const char* msg, void* a) {
  ofConsole.lockCerr() << "JPEG2000 info  : " << msg << endl;
  ofConsole.unlockCerr();
}

static inline int int_ceildivpow2(int a, int b) {
  return (a + (1 << b) - 1) >> b;
}

static OPJ_SIZE_T opj_read_from_buffer(void* p_buffer, OPJ_SIZE_T p_nb_bytes,
                                       opj_buffer_data* p_buffer_data) {
  return p_buffer_data->read((__uint8*)p_buffer, p_nb_bytes);
}

OPJ_UINT64 opj_get_data_length_from_buffer(opj_buffer_data* p_buffer_data) {
  return p_buffer_data->get_data_length();
}

static OPJ_SIZE_T opj_write_from_buffer(void* p_buffer, OPJ_SIZE_T p_nb_bytes,
                                        opj_buffer_data* p_buffer_data) {
  return p_buffer_data->write((__uint8*)p_buffer, p_nb_bytes);
}

static OPJ_OFF_T opj_skip_from_buffer(OPJ_OFF_T p_nb_bytes,
                                      opj_buffer_data* p_buffer_data) {
  return p_buffer_data->skip(p_nb_bytes);
}

static OPJ_BOOL opj_seek_from_buffer(OPJ_OFF_T p_nb_bytes,
                                     opj_buffer_data* p_buffer_data) {
  return p_buffer_data->seek(p_nb_bytes);
}

/* check file type */
int jpeg2000familytype(unsigned char* hdr, int hdr_len) {
  // check length
  if (hdr_len < 24)
    return -1;

  // check format
  if (hdr[0] == 0x00 && hdr[1] == 0x00 && hdr[2] == 0x00 && hdr[3] == 0x0C &&
      hdr[4] == 0x6A && hdr[5] == 0x50 && hdr[6] == 0x20 && hdr[7] == 0x20 &&
      hdr[20] == 0x6A && hdr[21] == 0x70 && hdr[22] == 0x32)
    // JP2 file format
    return JP2_CFMT;
  else if (hdr[0] == 0x00 && hdr[1] == 0x00 && hdr[2] == 0x00 &&
           hdr[3] == 0x0C && hdr[4] == 0x6A && hdr[5] == 0x50 &&
           hdr[6] == 0x20 && hdr[7] == 0x20 && hdr[20] == 0x6D &&
           hdr[21] == 0x6A && hdr[22] == 0x70 && hdr[23] == 0x32)
    // MJ2 file format
    return MJ2_CFMT;
  else if (hdr[0] == 0xFF && hdr[1] == 0x4F)
    // J2K file format
    return J2K_CFMT;
  else
    // unknown format
    return -1;
}

DJDecompressIJG2kBit::DJDecompressIJG2kBit(const DJCodecParameter& cp,
                                           OFBool isYBR)
    : DJDecoder(),
      cparam(&cp),
      cinfo(NULL),
      suspension(0),
      jsampBuffer(NULL),
      dicomPhotometricInterpretationIsYCbCr(isYBR),
      decompressedColorModel(EPI_Unknown) {}

DJDecompressIJG2kBit::~DJDecompressIJG2kBit() {
  cleanup();
}

OFCondition DJDecompressIJG2kBit::init() {
  // everything OK
  return EC_Normal;
}

void DJDecompressIJG2kBit::cleanup() {}

OFCondition DJDecompressIJG2kBit::decode(Uint8* compressedFrameBuffer,
                                         Uint32 compressedFrameBufferSize,
                                         Uint8* uncompressedFrameBuffer,
                                         Uint32 uncompressedFrameBufferSize,
                                         OFBool isSigned) {
  opj_dparameters_t parameters; /* decompression parameters */
  // opj_event_mgr_t event_mgr;    /* event manager */
  opj_image_t* image = 0L;
  opj_codec_t* dinfo; /* handle to a decompressor */
  // opj_cio_t *cio;
  unsigned char* src = (unsigned char*)compressedFrameBuffer;
  int file_length = compressedFrameBufferSize;

  int jpfamform;
  if ((jpfamform = jpeg2000familytype(compressedFrameBuffer, 24)) < 0)
    return makeOFCondition(OFM_dcmjpeg, 0, OF_error, "JPEG-2000 decode error");

  /* configure the event callbacks (not required) */
  /*memset(&event_mgr, 0, sizeof(opj_event_mgr_t));
  event_mgr.error_handler = error_callback;
  event_mgr.warning_handler = warning_callback;
  event_mgr.info_handler = info_callback;
  */
  /* set decoding parameters to default values */
  opj_set_default_decoder_parameters(&parameters);

  // default blindly copied
  // parameters.cp_layer=0;
  // parameters.cp_reduce=0;
  //   parameters.decod_format=-1;
  //   parameters.cod_format=-1;

  /* JPEG-2000 codestream */
  strncpy(parameters.infile, "", sizeof(parameters.infile) - 1);
  strncpy(parameters.outfile, "", sizeof(parameters.outfile) - 1);

  parameters.decod_format = jpfamform;
  parameters.cod_format = BMP_DFMT;

  /* get a decoder handle */
  if (jpfamform == JP2_CFMT || jpfamform == MJ2_CFMT) {
    dinfo = opj_create_decompress(OPJ_CODEC_JP2);
  } else if (jpfamform == J2K_CFMT) {
    dinfo = opj_create_decompress(OPJ_CODEC_J2K);
  } else {
    return makeOFCondition(OFM_dcmjpeg, 0, OF_error, "JPEG-2000 decode error");
  }
  // parameters.decod_format = 0;
  // parameters.cod_format = 1;

  /* get a decoder handle */
  // dinfo = opj_create_decompress(CODEC_J2K);

  /* catch events using our callbacks and give a local context */
  // opj_set_event_mgr((opj_common_ptr)dinfo, &event_mgr, NULL);
  opj_set_info_handler(dinfo, info_callback, stderr);
  opj_set_warning_handler(dinfo, warning_callback, stderr);
  opj_set_error_handler(dinfo, error_callback, stderr);

  /* setup the decoder decoding parameters using user parameters */
  opj_setup_decoder(dinfo, &parameters);

  /* open a byte stream */
  // cio = opj_cio_open((opj_common_ptr)dinfo, src, file_length);

  opj_stream_t* l_stream = opj_stream_default_create(OPJ_TRUE);
  opj_buffer_data* p_buffer = new opj_buffer_data(8192);
  p_buffer->write(src, file_length);
  opj_stream_set_user_data(l_stream, p_buffer);
  opj_stream_set_user_data_length(l_stream,
                                  opj_get_data_length_from_buffer(p_buffer));
  opj_stream_set_read_function(l_stream,
                               (opj_stream_read_fn)opj_read_from_buffer);
  opj_stream_set_write_function(l_stream,
                                (opj_stream_write_fn)opj_write_from_buffer);
  opj_stream_set_skip_function(l_stream,
                               (opj_stream_skip_fn)opj_skip_from_buffer);
  opj_stream_set_seek_function(l_stream,
                               (opj_stream_seek_fn)opj_seek_from_buffer);

  if (opj_read_header(l_stream, dinfo, &image) == OPJ_FALSE) {
    if (image != NULL)
      opj_image_destroy(image);
    if (dinfo != NULL)
      opj_destroy_codec(dinfo);
    if (l_stream != NULL)
      opj_stream_destroy(l_stream);
    delete p_buffer;
    return makeOFCondition(OFM_dcmjpeg, 0, OF_error, "JPEG-2000 decode error");
  }
  if (!opj_decode(dinfo, l_stream, image)) {
    if (image != NULL)
      opj_image_destroy(image);
    if (dinfo != NULL)
      opj_destroy_codec(dinfo);
    if (l_stream != NULL)
      opj_stream_destroy(l_stream);
    delete p_buffer;
    return makeOFCondition(OFM_dcmjpeg, 0, OF_error, "JPEG-2000 decode error");
  }

  if (!opj_end_decompress(dinfo, l_stream)) {
    if (image != NULL)
      opj_image_destroy(image);
    if (dinfo != NULL)
      opj_destroy_codec(dinfo);
    if (l_stream != NULL)
      opj_stream_destroy(l_stream);
    delete p_buffer;
    return makeOFCondition(OFM_dcmjpeg, 0, OF_error, "JPEG-2000 decode error");
  }

  /* decode the stream and fill the image structure */
  /*  image = opj_decode(dinfo, cio);
    if(!image)
  {
      opj_destroy_decompress(dinfo);
      opj_cio_close(cio);
      return makeOFCondition(OFM_dcmjpeg, 0, OF_error, "JPEG-2000 decode
  error");
    }
  */

  /* close the byte stream */
  // opj_cio_close(cio);

  /* free the memory containing the code-stream */

  printf("JP2K-DCMTK-Decode ");

  // Copy buffer
  for (int compno = 0; compno < image->numcomps; compno++) {
    opj_image_comp_t* comp = &image->comps[compno];

    int w = image->comps[compno].w;
    int wr =
        int_ceildivpow2(image->comps[compno].w, image->comps[compno].factor);
    int numcomps = image->numcomps;

    int hr =
        int_ceildivpow2(image->comps[compno].h, image->comps[compno].factor);

    if (wr == w && numcomps == 1) {
      if (comp->prec <= 8) {
        Uint8* data8 = (Uint8*)uncompressedFrameBuffer + compno;
        int* data = image->comps[compno].data;
        int i = wr * hr;
        while (i-- > 0)
          *data8++ = (Uint8)*data++;
      } else if (comp->prec <= 16) {
        Uint16* data16 = (Uint16*)uncompressedFrameBuffer + compno;
        int* data = image->comps[compno].data;
        int i = wr * hr;
        while (i-- > 0)
          *data16++ = (Uint16)*data++;
      } else {
        printf("****** 32-bit jpeg encoded is NOT supported\r");
        //			   uint32_t *data32 = (uint32_t*)raw + compno;
        //			   int *data = image->comps[compno].data;
        //			   int i = wr * hr;
        //			   while( i -- > 0)
        //				   *data32++ = (uint32_t) *data++;
      }
    } else {
      if (comp->prec <= 8) {
        Uint8* data8 = (Uint8*)uncompressedFrameBuffer + compno;
        for (int i = 0; i < wr * hr; i++) {
          *data8 = (Uint8)(image->comps[compno].data[i / wr * w + i % wr]);
          data8 += numcomps;
        }
      } else if (comp->prec <= 16) {
        Uint16* data16 = (Uint16*)uncompressedFrameBuffer + compno;
        for (int i = 0; i < wr * hr; i++) {
          *data16 = (Uint16)(image->comps[compno].data[i / wr * w + i % wr]);
          data16 += numcomps;
        }
      } else {
        printf("****** 32-bit jpeg encoded is NOT supported\r");
      }
    }
  }

  /* free remaining structures */
  if (image != NULL)
    opj_image_destroy(image);
  if (dinfo != NULL)
    opj_destroy_codec(dinfo);
  if (l_stream != NULL)
    opj_stream_destroy(l_stream);
  delete p_buffer;

  return EC_Normal;

  /*
    if (compressedFrameBuffer==NULL || uncompressedFrameBuffer==NULL) return
    EC_IllegalCall;

    const int pixelCount = cparam->getImageColumns()*cparam->getImageRows();
    int BytesAllocated = cparam->getImageBitsAllocated() / 8;

    opj_dparameters_t dparams;
    opj_event_mgr_t event_mgr;
    opj_image_t *image = NULL;
    opj_dinfo_t* dinfo = NULL;
    opj_cio_t *cio = NULL;

    memset(&event_mgr, 0, sizeof(opj_event_mgr_t));
    event_mgr.error_handler = opj_error_callback;
    if (cparam->isVerbose()) {
      event_mgr.warning_handler = opj_warning_callback;
      event_mgr.info_handler = opj_info_callback;
    }

    opj_set_default_decoder_parameters(&dparams);
    dparams.cp_layer=0;
    dparams.cp_reduce=0;

    try {
      dinfo = opj_create_decompress(CODEC_J2K);

      opj_set_event_mgr((opj_common_ptr)dinfo, &event_mgr, NULL);

      opj_setup_decoder(dinfo, &dparams);

      bool opj_err = false;
      dinfo->client_data = (void*)&opj_err;

      cio = opj_cio_open((opj_common_ptr)dinfo, compressedFrameBuffer,
    (int)compressedFrameBufferSize); image = opj_decode(dinfo, cio);
      //oldPixelData->Unload();

      if (image == NULL) return EJ_UnsupportedColorConversion;

        //throw gcnew DicomCodecException("Error in JPEG 2000 code stream!");
      for (int c = 0; c < image->numcomps; c++) {
        opj_image_comp_t* comp = &image->comps[c];

        int pos = cparam->getPlanarConfiguration() ? (c * pixelCount) : c;
        const int offset = cparam->getPlanarConfiguration()? 1 :
    image->numcomps;

        if (BytesAllocated == 1) {
          if (comp->sgnd) {
            const unsigned char sign = 1 << cparam->getImageHighBit();
            for (int p = 0; p < pixelCount; p++) {
              const int i = comp->data[p];
              if (i < 0)
                uncompressedFrameBuffer[pos] = (unsigned char)(-i | sign);
              else
                uncompressedFrameBuffer[pos] = (unsigned char)(i);
              pos += offset;
            }
          }
          else {
            for (int p = 0; p < pixelCount; p++) {
              uncompressedFrameBuffer[pos] = (unsigned char)comp->data[p];
              pos += offset;
            }
          }
        }
        else if (BytesAllocated == 2) {
          const unsigned short sign = 1 << cparam->getImageHighBit();
          unsigned short* destData16 = (unsigned short*)uncompressedFrameBuffer;
          if (comp->sgnd) {
            for (int p = 0; p < pixelCount; p++) {
              const int i = comp->data[p];
              if (i < 0)
                destData16[pos] = (unsigned short)(-i | sign);
              else
                destData16[pos] = (unsigned short)(i);
              pos += offset;
            }
          }
          else {
            for (int p = 0; p < pixelCount; p++) {
              destData16[pos] = (unsigned short)comp->data[p];
              pos += offset;
            }
          }
        }else{
          return EC_IllegalCall;//error JPEG 2000 module only supports Bytes
    Allocated == 8 or 16!
        }

      }

    } catch(std::exception& e){
    //} finally {
      if (cio != NULL)
        opj_cio_close(cio);
      if (dinfo != NULL)
        opj_destroy_decompress(dinfo);
      if (image != NULL)
        opj_image_destroy(image);

      return EC_IllegalCall;
    }
    if (cio != NULL)
      opj_cio_close(cio);
    if (dinfo != NULL)
      opj_destroy_decompress(dinfo);
    if (image != NULL)
      opj_image_destroy(image);

  */
}

void DJDecompressIJG2kBit::outputMessage() const {}

END_EXTERN_C