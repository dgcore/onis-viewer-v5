#ifndef DJEIJG2K_H
#define DJEIJG2K_H

#include "dcmtk/config/osconfig.h"
#include "dcmtk/dcmjpeg/djcodece.h" /* for class DJCodecEncoder */
#include "dcmtk/dcmjpeg/djencabs.h"
#include "dcmtk/ofstd/oflist.h"

typedef unsigned long
    vImagePixelCount; /* Pedantic: A number of pixels. For LP64 (ppc64) this is
                         a 64-bit quantity.  */

typedef struct vImage_Buffer {
  void* data;              /* Pointer to the top left pixel of the buffer.	*/
  vImagePixelCount height; /* The height (in pixels) of the buffer		*/
  vImagePixelCount width;  /* The width (in pixels) of the buffer 		*/
  size_t rowBytes;         /* The number of bytes in a pixel row		*/
} vImage_Buffer;

typedef Uint32 vImage_Flags; /* You must set all undefined flags bits to 0 */
typedef float Pixel_F;       // floating point planar pixel value
typedef unsigned long vDSP_Length;
typedef long vDSP_Stride;

class DJCodecParameter;

/** this class encapsulates the compression routines of the
 *  IJG JPEG library configured for 8 bits/sample.
 */
class DJCompressIJG2kBit : public DJEncoder {
public:
  DJCompressIJG2kBit(const DJCodecParameter& cp, EJ_Mode mode, Uint8 theQuality,
                     Uint8 theBitsPerSample,
                     E_TransferSyntax theSupportedTransferSyntax);

  /// destructor
  virtual ~DJCompressIJG2kBit();

  virtual OFCondition encode(Uint16 columns, Uint16 rows,
                             EP_Interpretation interpr, Uint16 samplesPerPixel,
                             Uint8* image_buffer, Uint8*& to, Uint32& length,
                             Uint8 pixelRepresentation, double minUsed,
                             double maxUsed);

  virtual OFCondition encode(Uint16 columns, Uint16 rows,
                             EP_Interpretation interpr, Uint16 samplesPerPixel,
                             Uint16* image_buffer, Uint8*& to, Uint32& length,
                             Uint8 pixelRepresentation, double minUsed,
                             double maxUsed);

  virtual OFCondition encode(Uint16 columns, Uint16 rows,
                             EP_Interpretation colorSpace,
                             Uint16 samplesPerPixel, Uint8* image_buffer,
                             Uint8*& to, Uint32& length, Uint8 bitsAllocated,
                             Uint8 pixelRepresentation, double minUsed,
                             double maxUsed);

  /** returns the number of bytes per sample that will be expected when
   * encoding.
   */
  virtual Uint16 bytesPerSample() const;

  /** returns the number of bits per sample that will be expected when encoding.
   */
  virtual Uint16 bitsPerSample() const;

  // virtual void outputMessage(void *arg) const;

private:
  DJCompressIJG2kBit(const DJCompressIJG2kBit&);

  DJCompressIJG2kBit& operator=(const DJCompressIJG2kBit&);

  const DJCodecParameter* cparam;

  void vImageConvert_Planar8toPlanarF(const vImage_Buffer* src,
                                      const vImage_Buffer* dest,
                                      Pixel_F maxFloat, Pixel_F minFloat,
                                      vImage_Flags flags);
  void vImageConvert_16SToF(const vImage_Buffer* src, const vImage_Buffer* dest,
                            float offset, float scale, vImage_Flags flags);
  void vImageConvert_16UToF(const vImage_Buffer* src, const vImage_Buffer* dest,
                            float offset, float scale, vImage_Flags flags);
  void vDSP_minv(float* A, vDSP_Stride I, float* C, vDSP_Length N);
  void vDSP_maxv(float* A, vDSP_Stride I, float* C, vDSP_Length N);

  void findMinMax(int& _min, int& _max, char* bytes, long length,
                  OFBool isSigned, int rows, int columns, int bitsAllocated);

  Uint8 quality;
  Uint8 bitsPerSampleValue;

  EJ_Mode modeofOperation;

  E_TransferSyntax supportedTransferSyntax;
};

#endif
