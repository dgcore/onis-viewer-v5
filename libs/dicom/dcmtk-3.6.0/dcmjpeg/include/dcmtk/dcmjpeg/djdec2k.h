#ifndef DJDEC2K_H
#define DJDEC2K_H

#include "dcmtk/config/osconfig.h"
#include "dcmtk/dcmjpeg/djcodecd.h" /* for class DJCodecDecoder */

/** Decoder class for JPEG 2K
 */
class DJDecoder2k : public DJCodecDecoder {
public:
  /// default constructor
  DJDecoder2k();

  /// destructor
  virtual ~DJDecoder2k();

  /** returns the transfer syntax that this particular codec
   *  is able to encode and decode.
   *  @return supported transfer syntax
   */
  virtual E_TransferSyntax supportedTransferSyntax() const;

  virtual OFBool isJPEG2000() const;

private:
  /** creates an instance of the compression library to be used for decoding.
   *  @param toRepParam representation parameter passed to decode()
   *  @param cp codec parameter passed to decode()
   *  @param bitsPerSample bits per sample for the image data
   *  @param isYBR flag indicating whether DICOM photometric interpretation is
   * YCbCr
   *  @return pointer to newly allocated decoder object
   */
  virtual DJDecoder* createDecoderInstance(
      const DcmRepresentationParameter* toRepParam, const DJCodecParameter* cp,
      Uint8 bitsPerSample, OFBool isYBR) const;
};

/** Decoder class for JPEG 2K LossLess
 */
class DJDecoder2kLossLess : public DJCodecDecoder {
public:
  /// default constructor
  DJDecoder2kLossLess();

  /// destructor
  virtual ~DJDecoder2kLossLess();

  /** returns the transfer syntax that this particular codec
   *  is able to encode and decode.
   *  @return supported transfer syntax
   */
  virtual E_TransferSyntax supportedTransferSyntax() const;

  virtual OFBool isJPEG2000() const;

private:
  /** creates an instance of the compression library to be used for decoding.
   *  @param toRepParam representation parameter passed to decode()
   *  @param cp codec parameter passed to decode()
   *  @param bitsPerSample bits per sample for the image data
   *  @param isYBR flag indicating whether DICOM photometric interpretation is
   * YCbCr
   *  @return pointer to newly allocated decoder object
   */
  virtual DJDecoder* createDecoderInstance(
      const DcmRepresentationParameter* toRepParam, const DJCodecParameter* cp,
      Uint8 bitsPerSample, OFBool isYBR) const;
};

#endif
