
#include "dcmtk/dcmjpeg/djenc2k.h"
#include "dcmtk/config/osconfig.h"
#include "dcmtk/dcmjpeg/djcparam.h"
#include "dcmtk/dcmjpeg/djeijg2k.h"
#include "dcmtk/dcmjpeg/djrploss.h"

DJEncoder2k::DJEncoder2k() : DJCodecEncoder() {}

DJEncoder2k::~DJEncoder2k() {}

E_TransferSyntax DJEncoder2k::supportedTransferSyntax() const {
  return EXS_JPEG2000;
}

OFBool DJEncoder2k::isLosslessProcess() const {
  return OFFalse;
}

void DJEncoder2k::createDerivationDescription(
    const DcmRepresentationParameter* toRepParam,
    const DJCodecParameter* /* cp */, Uint8 /* bitsPerSample */, double ratio,
    OFString& derivationDescription) const {
  DJ_RPLossy defaultRP;
  const DJ_RPLossy* rp =
      toRepParam ? (const DJ_RPLossy*)toRepParam : &defaultRP;
  char buf[64];

  derivationDescription = "Lossy compression with JPEG 2K ";
  sprintf(buf, "%u", rp->getQuality());
  derivationDescription += buf;
  derivationDescription += ", compression ratio ";
  appendCompressionRatio(derivationDescription, ratio);
}

DJEncoder* DJEncoder2k::createEncoderInstance(
    const DcmRepresentationParameter* toRepParam, const DJCodecParameter* cp,
    Uint8 bitsPerSample) const {
  DJ_RPLossy defaultRP;
  const DJ_RPLossy* rp =
      toRepParam ? (const DJ_RPLossy*)toRepParam : &defaultRP;
  DJCompressIJG2kBit* result = new DJCompressIJG2kBit(
      *cp, EJM_JP2K_lossy, rp->getQuality(), bitsPerSample, EXS_JPEG2000);

  return result;
}

// *************

DJEncoder2kLossLess::DJEncoder2kLossLess() : DJCodecEncoder() {}

DJEncoder2kLossLess::~DJEncoder2kLossLess() {}

E_TransferSyntax DJEncoder2kLossLess::supportedTransferSyntax() const {
  return EXS_JPEG2000LosslessOnly;
}

OFBool DJEncoder2kLossLess::isLosslessProcess() const {
  return OFTrue;
}

void DJEncoder2kLossLess::createDerivationDescription(
    const DcmRepresentationParameter* toRepParam,
    const DJCodecParameter* /* cp */, Uint8 /* bitsPerSample */, double ratio,
    OFString& derivationDescription) const {
  DJ_RPLossy defaultRP;
  const DJ_RPLossy* rp =
      toRepParam ? (const DJ_RPLossy*)toRepParam : &defaultRP;
  // char buf[64];

  derivationDescription = "LossLess compression with JPEG 2K";
  derivationDescription += ", compression ratio ";
  appendCompressionRatio(derivationDescription, ratio);
}

DJEncoder* DJEncoder2kLossLess::createEncoderInstance(
    const DcmRepresentationParameter* toRepParam, const DJCodecParameter* cp,
    Uint8 bitsPerSample) const {
  DJ_RPLossy defaultRP;
  const DJ_RPLossy* rp =
      toRepParam ? (const DJ_RPLossy*)toRepParam : &defaultRP;
  DJCompressIJG2kBit* result =
      new DJCompressIJG2kBit(*cp, EJM_JP2K_lossless, rp->getQuality(),
                             bitsPerSample, EXS_JPEG2000LosslessOnly);

  return result;
}
