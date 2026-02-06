
#ifndef DJDIJG2K_H
#define DJDIJG2K_H

#include "dcmtk/config/osconfig.h"
#include "dcmtk/dcmjpeg/djdecabs.h" /* for class DJDecoder */

extern "C" {
struct jpeg_decompress_struct;
}

class DJCodecParameter;

class DJDecompressIJG2kBit : public DJDecoder {
public:
  DJDecompressIJG2kBit(const DJCodecParameter& cp, OFBool isYBR);
  virtual ~DJDecompressIJG2kBit();
  virtual OFCondition init();
  virtual OFCondition decode(Uint8* compressedFrameBuffer,
                             Uint32 compressedFrameBufferSize,
                             Uint8* uncompressedFrameBuffer,
                             Uint32 uncompressedFrameBufferSize,
                             OFBool isSigned);

  virtual Uint16 bytesPerSample() const {
    return sizeof(Uint16);
  }

  virtual EP_Interpretation getDecompressedColorModel() const {
    return decompressedColorModel;
  }

  virtual void outputMessage() const;

private:
  DJDecompressIJG2kBit(const DJDecompressIJG2kBit&);
  DJDecompressIJG2kBit& operator=(const DJDecompressIJG2kBit&);
  void cleanup();

  const DJCodecParameter* cparam;
  jpeg_decompress_struct* cinfo;
  int suspension;
  void* jsampBuffer;
  OFBool dicomPhotometricInterpretationIsYCbCr;
  EP_Interpretation decompressedColorModel;
};

#endif
