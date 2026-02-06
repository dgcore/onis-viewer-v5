
#ifndef DJENC2K_H
#define DJENC2K_H

#include "dcmtk/config/osconfig.h"
#include "dcmtk/dcmjpeg/djcodece.h" /* for class DJCodecEncoder */

class DJEncoder2k : public DJCodecEncoder {
public:
  /// default constructor
  DJEncoder2k();

  /// destructor
  virtual ~DJEncoder2k();

  /** returns the transfer syntax that this particular codec
   *  is able to encode and decode.
   *  @return supported transfer syntax
   */
  virtual E_TransferSyntax supportedTransferSyntax() const;

private:
  /** returns true if the transfer syntax supported by this
   *  codec is lossless.
   *  @return lossless flag
   */
  virtual OFBool isLosslessProcess() const;

  /** creates 'derivation description' string after encoding.
   *  @param toRepParam representation parameter passed to encode()
   *  @param cp codec parameter passed to encode()
   *  @param bitsPerSample bits per sample of the original image data prior to
   * compression
   *  @param ratio image compression ratio. This is not the "quality factor"
   *    but the real effective ratio between compressed and uncompressed image,
   *    i. e. 30 means a 30:1 lossy compression.
   *  @param imageComments image comments returned in this
   *    parameter which is initially empty
   */
  virtual void createDerivationDescription(
      const DcmRepresentationParameter* toRepParam, const DJCodecParameter* cp,
      Uint8 bitsPerSample, double ratio, OFString& derivationDescription) const;

  /** creates an instance of the compression library to be used
   *  for encoding/decoding.
   *  @param toRepParam representation parameter passed to encode()
   *  @param cp codec parameter passed to encode()
   *  @param bitsPerSample bits per sample for the image data
   *  @return pointer to newly allocated codec object
   */
  virtual DJEncoder* createEncoderInstance(
      const DcmRepresentationParameter* toRepParam, const DJCodecParameter* cp,
      Uint8 bitsPerSample) const;
};

class DJEncoder2kLossLess : public DJCodecEncoder {
public:
  /// default constructor
  DJEncoder2kLossLess();

  /// destructor
  virtual ~DJEncoder2kLossLess();

  virtual E_TransferSyntax supportedTransferSyntax() const;

private:
  virtual OFBool isLosslessProcess() const;

  virtual void createDerivationDescription(
      const DcmRepresentationParameter* toRepParam, const DJCodecParameter* cp,
      Uint8 bitsPerSample, double ratio, OFString& derivationDescription) const;

  virtual DJEncoder* createEncoderInstance(
      const DcmRepresentationParameter* toRepParam, const DJCodecParameter* cp,
      Uint8 bitsPerSample) const;
};

#endif
