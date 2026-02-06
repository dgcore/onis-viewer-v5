#include "dcmtk/dcmjpeg/djdec2k.h"
#include "dcmtk/config/osconfig.h"
#include "dcmtk/dcmjpeg/djcparam.h"
#include "dcmtk/dcmjpeg/djrploss.h"

#include "dcmtk/dcmjpeg/djdijg2k.h"

DJDecoder2k::DJDecoder2k() : DJCodecDecoder() {}

DJDecoder2k::~DJDecoder2k() {}

E_TransferSyntax DJDecoder2k::supportedTransferSyntax() const {
  return EXS_JPEG2000;
}

DJDecoder* DJDecoder2k::createDecoderInstance(
    const DcmRepresentationParameter* /* toRepParam */,
    const DJCodecParameter* cp, Uint8 /* bitsPerSample */, OFBool isYBR) const {
  return new DJDecompressIJG2kBit(*cp, isYBR);
}
OFBool DJDecoder2k::isJPEG2000() const {
  return OFTrue;
}

// **************

DJDecoder2kLossLess::DJDecoder2kLossLess() : DJCodecDecoder() {}

DJDecoder2kLossLess::~DJDecoder2kLossLess() {}

E_TransferSyntax DJDecoder2kLossLess::supportedTransferSyntax() const {
  return EXS_JPEG2000LosslessOnly;
}

DJDecoder* DJDecoder2kLossLess::createDecoderInstance(
    const DcmRepresentationParameter* /* toRepParam */,
    const DJCodecParameter* cp, Uint8 bitsPerSample, OFBool isYBR) const {
  return new DJDecompressIJG2kBit(*cp, isYBR);
}

OFBool DJDecoder2kLossLess::isJPEG2000() const {
  return OFTrue;
}