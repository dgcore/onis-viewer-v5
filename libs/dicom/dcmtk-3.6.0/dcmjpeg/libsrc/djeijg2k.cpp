#include "dcmtk/dcmjpeg/djeijg2k.h"
#include "dcmtk/config/osconfig.h"
#include "dcmtk/dcmdata/dcerror.h"
#include "dcmtk/dcmjpeg/djcparam.h"
#include "dcmtk/dcmjpeg/opjbufferdata.h"
#include "dcmtk/ofstd/ofconsol.h"

#define INCLUDE_CSTDIO
#define INCLUDE_CSETJMP
#include "dcmtk/ofstd/ofstdinc.h"

// These two macros are re-defined in the IJG header files.
// We undefine them here and hope that IJG's configure has
// come to the same conclusion that we have...
#ifdef HAVE_STDLIB_H
#undef HAVE_STDLIB_H
#endif
#ifdef HAVE_STDDEF_H
#undef HAVE_STDDEF_H
#endif

// use 16K blocks for temporary storage of compressed JPEG data
#define IJGE12_BLOCKSIZE 16384

#include "openjpeg.h"

static void error_callback(const char* msg, void* a) {
  ofConsole.lockCerr() << "JPEG2000  error : " << msg << endl;
  ofConsole.unlockCerr();
}
static void warning_callback(const char* msg, void* a) {
  ofConsole.lockCerr() << "JPEG2000  warning : " << msg << endl;
  ofConsole.unlockCerr();
}
static void info_callback(const char* msg, void* a) {
  ofConsole.lockCerr() << "JPEG2000  info : " << msg << endl;
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

DJCompressIJG2kBit::DJCompressIJG2kBit(
    const DJCodecParameter& cp, EJ_Mode mode, Uint8 theQuality,
    Uint8 theBitsPerSample, E_TransferSyntax theSupportedTransferSyntax)
    : DJEncoder(),
      cparam(&cp),
      quality(theQuality),
      bitsPerSampleValue(theBitsPerSample),
      modeofOperation(mode),
      supportedTransferSyntax(theSupportedTransferSyntax) {}

DJCompressIJG2kBit::~DJCompressIJG2kBit() {}

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

static opj_image_t* rawtoimage(char* inputbuffer, opj_cparameters_t* parameters,
                               int fragment_size, int image_width,
                               int image_height, int sample_pixel,
                               int bitsallocated, int bitsstored, int sign,
                               int pc) {
  int w, h;
  int numcomps;
  OPJ_COLOR_SPACE color_space;
  opj_image_cmptparm_t cmptparm[3]; /* maximum of 3 components */
  opj_image_t* image = NULL;

  assert(sample_pixel == 1 || sample_pixel == 3);
  if (sample_pixel == 1) {
    numcomps = 1;
    color_space = OPJ_CLRSPC_GRAY;
  } else  // sample_pixel == 3
  {
    numcomps = 3;
    color_space = OPJ_CLRSPC_SRGB;
    /* Does OpenJPEg support: CLRSPC_SYCC ?? */
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

  /* create the image */
  image = opj_image_create(numcomps, &cmptparm[0], color_space);
  if (!image) {
    return NULL;
  }
  /* set image offset and reference grid */
  image->x0 = parameters->image_offset_x0;
  image->y0 = parameters->image_offset_y0;
  image->x1 = parameters->image_offset_x0 + (w - 1) * subsampling_dx + 1;
  image->y1 = parameters->image_offset_y0 + (h - 1) * subsampling_dy + 1;

  /* set image data */

  // assert( fragment_size == numcomps*w*h*(bitsallocated/8) );
  if (bitsallocated <= 8) {
    if (sign) {
      rawtoimage_fill<Sint8>((Sint8*)inputbuffer, w, h, numcomps, image, pc);
    } else {
      rawtoimage_fill<Uint8>((Uint8*)inputbuffer, w, h, numcomps, image, pc);
    }
  } else if (bitsallocated <= 16) {
    if (sign) {
      rawtoimage_fill<Sint16>((Sint16*)inputbuffer, w, h, numcomps, image, pc);
    } else {
      rawtoimage_fill<Uint16>((Uint16*)inputbuffer, w, h, numcomps, image, pc);
    }
  } else if (bitsallocated <= 32) {
    if (sign) {
      rawtoimage_fill<Sint32>((Sint32*)inputbuffer, w, h, numcomps, image, pc);
    } else {
      rawtoimage_fill<Uint32>((Uint32*)inputbuffer, w, h, numcomps, image, pc);
    }
  } else {
    return NULL;
  }

  return image;
}

void DJCompressIJG2kBit::vImageConvert_Planar8toPlanarF(
    const vImage_Buffer* src, const vImage_Buffer* dest, Pixel_F maxFloat,
    Pixel_F minFloat, vImage_Flags flags) {
  int x, y;
  char* uip_srcline;
  float* fp_destline;

  for (y = 0; y < src->height; y++) {
    uip_srcline = (char*)&((unsigned char*)src->data)[y * src->rowBytes];
    fp_destline = (float*)&((unsigned char*)dest->data)[y * dest->rowBytes];

    for (x = 0; x < src->width; x++) {
      fp_destline[x] =
          (float)uip_srcline[x] * (maxFloat - minFloat) / 255.0f + minFloat;
    }
  }
}

void DJCompressIJG2kBit::vImageConvert_16SToF(const vImage_Buffer* src,
                                              const vImage_Buffer* dest,
                                              float offset, float scale,
                                              vImage_Flags flags) {
  int x, y;
  Sint16* uip_srcline;
  float* fp_destline;

  for (y = 0; y < src->height; y++) {
    uip_srcline = (Sint16*)&((unsigned char*)src->data)[y * src->rowBytes];
    fp_destline = (float*)&((unsigned char*)dest->data)[y * dest->rowBytes];

    for (x = 0; x < src->width; x++) {
      fp_destline[x] = (float)uip_srcline[x] * scale + offset;
    }
  }
}

void DJCompressIJG2kBit::vImageConvert_16UToF(const vImage_Buffer* src,
                                              const vImage_Buffer* dest,
                                              float offset, float scale,
                                              vImage_Flags flags) {
  int x, y;
  Uint16* uip_srcline;
  float* fp_destline;

  for (y = 0; y < src->height; y++) {
    uip_srcline = (Uint16*)&((unsigned char*)src->data)[y * src->rowBytes];
    fp_destline = (float*)&((unsigned char*)dest->data)[y * dest->rowBytes];

    for (x = 0; x < src->width; x++) {
      fp_destline[x] = (float)uip_srcline[x] * scale + offset;
    }
  }
}

void DJCompressIJG2kBit::vDSP_minv(float* A, vDSP_Stride I, float* C,
                                   vDSP_Length N) {
  if (!A)
    return;
  long l;
  *C = A[0];
  for (l = 1; l < N; l += I) {
    if (*C > A[l])
      *C = A[l];
  }
}
void DJCompressIJG2kBit::vDSP_maxv(float* A, vDSP_Stride I, float* C,
                                   vDSP_Length N) {
  if (!A)
    return;
  long l;
  *C = A[0];
  for (l = 1; l < N; l += I) {
    if (*C < A[l])
      *C = A[l];
  }
}

void DJCompressIJG2kBit::findMinMax(int& _min, int& _max, char* bytes,
                                    long length, OFBool isSigned, int rows,
                                    int columns, int bitsAllocated) {
  int i = 0;
  float max, min;

  if (bitsAllocated <= 8)
    length = length;
  else if (bitsAllocated <= 16)
    length = length / 2;
  else
    length = length / 4;

  float* fBuffer = (float*)malloc(length * 4);
  if (fBuffer) {
    vImage_Buffer src, dstf;
    dstf.height = src.height = rows;
    dstf.width = src.width = columns;
    dstf.rowBytes = columns * sizeof(float);
    dstf.data = fBuffer;
    src.data = (void*)bytes;

    if (bitsAllocated <= 8) {
      src.rowBytes = columns;
      vImageConvert_Planar8toPlanarF(&src, &dstf, 0, 256, 0);
    } else if (bitsAllocated <= 16) {
      src.rowBytes = columns * 2;

      if (isSigned)
        vImageConvert_16SToF(&src, &dstf, 0, 1, 0);
      else
        vImageConvert_16UToF(&src, &dstf, 0, 1, 0);
    }

    vDSP_minv(fBuffer, 1, &min, length);
    vDSP_maxv(fBuffer, 1, &max, length);

    _min = min;
    _max = max;

    //		// The goal of this 'trick' is to avoid the problem that some
    // annotations can generate, if they are 'incrusted' in the image
    //		// the jp2k algorithm doesn't like them at all...
    //
    //		if( isSigned == NO && _max == 65535)
    //		{
    //			long i = _columns * _rows;
    //			// Compute the new max
    //			while( i-->0)
    //			{
    //				if( fBuffer[ i] == 0xFFFF)
    //					fBuffer[ i] = _min;
    //			}
    //
    //			vDSP_minv( fBuffer, 1, &min, length);
    //			vDSP_maxv( fBuffer, 1, &max, length);
    //
    //			_min = min;
    //			_max = max;
    //
    //			// Modify the original data
    //
    //			unsigned short *ptr = (unsigned short*) bytes;
    //
    //			i = _columns * _rows;
    //			while( i-->0)
    //			{
    //				if( ptr[ i] == 0xFFFF)
    //					ptr[ i] = _max;
    //			}
    //		}

    free(fBuffer);
  }
}

OFCondition DJCompressIJG2kBit::encode(
    Uint16 columns, Uint16 rows, EP_Interpretation colorSpace,
    Uint16 samplesPerPixel, Uint8* image_buffer, Uint8*& to, Uint32& length,
    Uint8 pixelRepresentation, double minUsed, double maxUsed) {
  return encode(columns, rows, colorSpace, samplesPerPixel,
                (Uint8*)image_buffer, to, length, 8, pixelRepresentation,
                minUsed, maxUsed);
}

OFCondition DJCompressIJG2kBit::encode(
    Uint16 columns, Uint16 rows, EP_Interpretation interpr,
    Uint16 samplesPerPixel, Uint16* image_buffer, Uint8*& to, Uint32& length,
    Uint8 pixelRepresentation, double minUsed, double maxUsed) {
  return encode(columns, rows, interpr, samplesPerPixel, (Uint8*)image_buffer,
                to, length, 16, pixelRepresentation, minUsed, maxUsed);
}

Uint16 DJCompressIJG2kBit::bytesPerSample() const {
  if (bitsPerSampleValue <= 8)
    return 1;
  else
    return 2;
}

Uint16 DJCompressIJG2kBit::bitsPerSample() const {
  return bitsPerSampleValue;
}

OFCondition DJCompressIJG2kBit::encode(Uint16 columns, Uint16 rows,
                                       EP_Interpretation colorSpace,
                                       Uint16 samplesPerPixel,
                                       Uint8* image_buffer, Uint8*& to,
                                       Uint32& length, Uint8 bitsAllocated,
                                       Uint8 pixelRepresentation,
                                       double minUsed, double maxUsed) {
  /*
  if ((oldPixelData->PhotometricInterpretation == "YBR_FULL_422")    ||
    (oldPixelData->PhotometricInterpretation == "YBR_PARTIAL_422") ||
    (oldPixelData->PhotometricInterpretation == "YBR_PARTIAL_420"))
    throw gcnew DicomCodecException(String::Format("Photometric Interpretation
  '{0}' not supported by JPEG 2000 encoder",
                            oldPixelData->PhotometricInterpretation));

  DcmJpeg2000Parameters^ jparams = (DcmJpeg2000Parameters^)parameters;
  if (jparams == nullptr)
    jparams = (DcmJpeg2000Parameters^)GetDefaultParameters();

  int pixelCount = oldPixelData->ImageHeight * oldPixelData->ImageWidth;

  for (int frame = 0; frame < oldPixelData->NumberOfFrames; frame++) {
    array<unsigned char>^ frameArray = oldPixelData->GetFrameDataU8(frame);
    pin_ptr<unsigned char> framePin = &frameArray[0];
    unsigned char* frameData = framePin;
    const int frameDataSize = frameArray->Length;

    opj_image_cmptparm_t cmptparm[3];
    opj_cparameters_t eparams;  // compression parameters
    opj_event_mgr_t event_mgr;  // event manager
    opj_cinfo_t* cinfo = NULL;  // handle to a compressor
    opj_image_t *image = NULL;
    opj_cio_t *cio = NULL;

    memset(&event_mgr, 0, sizeof(opj_event_mgr_t));
    event_mgr.error_handler = opj_error_callback;
    if (jparams->IsVerbose) {
      event_mgr.warning_handler = opj_warning_callback;
      event_mgr.info_handler = opj_info_callback;
    }

    cinfo = opj_create_compress(CODEC_J2K);

    opj_set_event_mgr((opj_common_ptr)cinfo, &event_mgr, NULL);

    opj_set_default_encoder_parameters(&eparams);
    eparams.cp_disto_alloc = 1;

    if (newPixelData->TransferSyntax == DicomTransferSyntax::JPEG2000Lossy &&
  jparams->Irreversible) eparams.irreversible = 1;

    int r = 0;
    for (; r < jparams->RateLevels->Length; r++) {
      if (jparams->RateLevels[r] > jparams->Rate) {
        eparams.tcp_numlayers++;
        eparams.tcp_rates[r] = (float)jparams->RateLevels[r];
      } else
        break;
    }
    eparams.tcp_numlayers++;
    eparams.tcp_rates[r] = (float)jparams->Rate;

    if (newPixelData->TransferSyntax == DicomTransferSyntax::JPEG2000Lossless &&
  jparams->Rate > 0) eparams.tcp_rates[eparams.tcp_numlayers++] = 0;

    if (oldPixelData->PhotometricInterpretation == "RGB" && jparams->AllowMCT)
      eparams.tcp_mct = 1;

    memset(&cmptparm[0], 0, sizeof(opj_image_cmptparm_t) * 3);
    for (int i = 0; i < oldPixelData->SamplesPerPixel; i++) {
      cmptparm[i].bpp = oldPixelData->BitsAllocated;
      cmptparm[i].prec = oldPixelData->BitsStored;
      if (!jparams->EncodeSignedPixelValuesAsUnsigned)
        cmptparm[i].sgnd = oldPixelData->PixelRepresentation;
      cmptparm[i].dx = eparams.subsampling_dx;
      cmptparm[i].dy = eparams.subsampling_dy;
      cmptparm[i].h = oldPixelData->ImageHeight;
      cmptparm[i].w = oldPixelData->ImageWidth;
    }

    try {
      OPJ_COLOR_SPACE color_space =
  getOpenJpegColorSpace(oldPixelData->PhotometricInterpretation); image =
  opj_image_create(oldPixelData->SamplesPerPixel, &cmptparm[0], color_space);

      image->x0 = eparams.image_offset_x0;
      image->y0 = eparams.image_offset_y0;
      image->x1 =	image->x0 + ((oldPixelData->ImageWidth - 1) *
  eparams.subsampling_dx) + 1; image->y1 =	image->y0 +
  ((oldPixelData->ImageHeight - 1) * eparams.subsampling_dy) + 1;

      for (int c = 0; c < image->numcomps; c++) {
        opj_image_comp_t* comp = &image->comps[c];

        int pos = oldPixelData->IsPlanar ? (c * pixelCount) : c;
        const int offset = oldPixelData->IsPlanar ? 1 : image->numcomps;

        if (oldPixelData->BytesAllocated == 1) {
          if (comp->sgnd) {
            if (oldPixelData->BitsStored < 8) {
              const unsigned char sign = 1 << oldPixelData->HighBit;
              const unsigned char mask = sign - 1;
              for (int p = 0; p < pixelCount; p++) {
                const unsigned char pixel = frameData[pos];
                if (pixel & sign)
                  comp->data[p] = -(pixel & mask);
                else
                  comp->data[p] = pixel;
                pos += offset;
              }
            }
            else {
              char* frameData8 = (char*)frameData;
              for (int p = 0; p < pixelCount; p++) {
                comp->data[p] = frameData8[pos];
                pos += offset;
              }
            }
          }
          else {
            for (int p = 0; p < pixelCount; p++) {
              comp->data[p] = frameData[pos];
              pos += offset;
            }
          }
        }
        else if (oldPixelData->BytesAllocated == 2) {
          if (comp->sgnd) {
            if (oldPixelData->BitsStored < 16) {
              unsigned short* frameData16 = (unsigned short*)frameData;
              const unsigned short sign = 1 << oldPixelData->HighBit;
              const unsigned short mask = sign - 1;
              for (int p = 0; p < pixelCount; p++) {
                const unsigned short pixel = frameData16[pos];
                if (pixel & sign)
                  comp->data[p] = -(pixel & mask);
                else
                  comp->data[p] = pixel;
                pos += offset;
              }
            }
            else {
              short* frameData16 = (short*)frameData;
              for (int p = 0; p < pixelCount; p++) {
                comp->data[p] = frameData16[pos];
                pos += offset;
              }
            }
          }
          else {
            unsigned short* frameData16 = (unsigned short*)frameData;
            for (int p = 0; p < pixelCount; p++) {
              comp->data[p] = frameData16[pos];
              pos += offset;
            }
          }
        }
        else
          throw gcnew DicomCodecException("JPEG 2000 codec only supports Bits
  Allocated == 8 or 16");
      }

      opj_setup_encoder(cinfo, &eparams, image);

      cio = opj_cio_open((opj_common_ptr)cinfo, NULL, 0);

      if (opj_encode(cinfo, cio, image, eparams.index)) {
        int clen = cio_tell(cio);
        array<unsigned char>^ cbuf = gcnew array<unsigned char>(clen);
        Marshal::Copy((IntPtr)cio->buffer, cbuf, 0, clen);
        newPixelData->AddFrame(cbuf);
      } else
        throw gcnew DicomCodecException("Unable to JPEG 2000 encode image");

      if (oldPixelData->PhotometricInterpretation == "RGB" && jparams->AllowMCT)
  { if (jparams->UpdatePhotometricInterpretation) { if
  (newPixelData->TransferSyntax == DicomTransferSyntax::JPEG2000Lossy &&
  jparams->Irreversible) newPixelData->PhotometricInterpretation = "YBR_ICT";
          else
            newPixelData->PhotometricInterpretation = "YBR_RCT";
        }
      }

      if (newPixelData->TransferSyntax == DicomTransferSyntax::JPEG2000Lossy &&
  jparams->Irreversible) { newPixelData->IsLossy = true;
        newPixelData->LossyCompressionMethod = "ISO_15444_1";

        const double oldSize = oldPixelData->GetFrameSize(0);
        const double newSize = newPixelData->GetFrameSize(0);
        String^ ratio = String::Format("{0:0.000}", oldSize / newSize);
        newPixelData->LossyCompressionRatio = ratio;
      }
    } catch(std::exception& e){
    //}finally {
      if (cio != NULL)
        opj_cio_close(cio);
      if (image != NULL)
        opj_image_destroy(image);
      if (cinfo != NULL)
        opj_destroy_compress(cinfo);
    }
  }

  if (cio != NULL)
    opj_cio_close(cio);
  if (image != NULL)
    opj_image_destroy(image);
  if (cinfo != NULL)
    opj_destroy_compress(cinfo);

  */
  // return EC_Normal;

  opj_cparameters_t parameters;
  // opj_event_mgr_t event_mgr;
  opj_image_t* image = NULL;

  printf("JP2K-DCMTK-Encode ");

  /*
  memset(&event_mgr, 0, sizeof(opj_event_mgr_t));
  event_mgr.error_handler = error_callback;
  event_mgr.warning_handler = warning_callback;
  event_mgr.info_handler = info_callback;
  */

  memset(&parameters, 0, sizeof(parameters));
  opj_set_default_encoder_parameters(&parameters);

  parameters.tcp_numlayers = 1;
  parameters.cp_disto_alloc = 1;

  switch (quality) {
    case 0:  // DCMLosslessQuality
      parameters.tcp_rates[0] = 0;
      break;

    case 1:  // DCMHighQuality
      parameters.tcp_rates[0] = 4;
      break;

    case 2:  // DCMMediumQuality
      if (columns <= 600 || rows <= 600)
        parameters.tcp_rates[0] = 6;
      else
        parameters.tcp_rates[0] = 8;
      break;

    case 3:  // DCMLowQuality
      parameters.tcp_rates[0] = 16;
      break;

    default:
      printf("****** warning unknown compression rate -> lossless : %d",
             quality);
      parameters.tcp_rates[0] = 0;
      break;
  }

  int image_width = columns;
  int image_height = rows;
  int sample_pixel = samplesPerPixel;

  if (colorSpace == EPI_Monochrome1 || colorSpace == EPI_Monochrome2) {
  } else {
    if (sample_pixel != 3)
      printf("*** RGB Photometric?, but... SamplesPerPixel != 3 ?");
    sample_pixel = 3;
  }

  int bitsstored = bitsAllocated;

  OFBool isSigned = 0;

  if (bitsAllocated >= 16) {
    if (minUsed == 0 && maxUsed == 0) {
      int _min = 0, _max = 0;
      findMinMax(_min, _max, (char*)image_buffer,
                 columns * rows * samplesPerPixel * bitsAllocated / 8, isSigned,
                 rows, columns, bitsAllocated);

      minUsed = _min;
      maxUsed = _max;
    }

    int amplitude = maxUsed;

    if (minUsed < 0)
      amplitude -= minUsed;

    int bits = 1, value = 2;

    while (value < amplitude) {
      value *= 2;
      bits++;
    }

    if (minUsed < 0)
      bits++;

    if (bits < 9)
      bits = 9;

    // avoid the artifacts... switch to lossless
    if ((maxUsed >= 32000 && minUsed <= -32000) || maxUsed >= 65000 ||
        bits > 16) {
      parameters.tcp_rates[0] = 0;
      parameters.tcp_numlayers = 1;
      parameters.cp_disto_alloc = 1;
    }

    if (bits > 16)
      bits = 16;

    bitsstored = bits;
  }

  image = rawtoimage(
      (char*)image_buffer, &parameters,
      static_cast<int>(columns * rows * samplesPerPixel * bitsAllocated / 8),
      image_width, image_height, sample_pixel, bitsAllocated, bitsstored,
      isSigned, 0);

  parameters.cod_format = 0;  // J2K format output
  int codestream_length;
  // opj_cio_t *cio = NULL;

  opj_codec_t* cinfo = opj_create_compress(OPJ_CODEC_J2K);

  // catch events using our callbacks and give a local context
  // opj_set_event_mgr((opj_common_ptr)cinfo, &event_mgr, stderr);
  opj_set_info_handler(cinfo, info_callback, stderr);
  opj_set_warning_handler(cinfo, warning_callback, stderr);
  opj_set_error_handler(cinfo, error_callback, stderr);

  // setup the encoder parameters using the current image and using user
  // parameters
  opj_setup_encoder(cinfo, &parameters, image);

  // open a byte stream for writing
  // allocate memory for all tiles
  // cio = opj_cio_open((opj_common_ptr)cinfo, NULL, 0);
  opj_stream_t* l_stream = opj_stream_default_create(OPJ_FALSE);
  opj_buffer_data* p_buffer = new opj_buffer_data(8192);
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

  OPJ_BOOL bSuccess = opj_start_compress(cinfo, image, l_stream);
  if (bSuccess == OPJ_FALSE) {
    opj_stream_destroy(l_stream);
    delete p_buffer;
    fprintf(stderr, "failed to encode image\n");
    return makeOFCondition(OFM_dcmjpeg, 0, OF_error,
                           "JPEG-2000 error : failed to encode image");
  } else {
    // encode the image
    bSuccess = opj_encode(cinfo, l_stream);
    if (bSuccess == OPJ_FALSE) {
      opj_stream_destroy(l_stream);
      delete p_buffer;
      fprintf(stderr, "failed to encode image\n");
      return makeOFCondition(OFM_dcmjpeg, 0, OF_error,
                             "JPEG-2000 error : failed to encode image");
    } else {
      bSuccess = opj_end_compress(cinfo, l_stream);
      if (bSuccess == OPJ_FALSE) {
        opj_stream_destroy(l_stream);
        delete p_buffer;
        fprintf(stderr, "failed to encode image\n");
        return makeOFCondition(OFM_dcmjpeg, 0, OF_error,
                               "JPEG-2000 error : failed to encode image");
      }
    }
  }

  codestream_length = p_buffer->get_data_length();

  to = new Uint8[codestream_length];
  p_buffer->it_index = 0;
  p_buffer->pos = 0;
  memset(to, 1, codestream_length);
  p_buffer->read(to, codestream_length);

  // memcpy( to, p_buffer, codestream_length);
  length = codestream_length;

  // close and free the byte stream
  if (l_stream)
    opj_stream_destroy(l_stream);

  // free remaining compression structures
  if (cinfo)
    opj_destroy_codec(cinfo);

  if (image)
    opj_image_destroy(image);

  delete p_buffer;

  return EC_Normal;
}
