class DicomTags {
  const DicomTags._();

  static const String tagSpecificCharacterSet = "0008:0005";

  static const String tagTransferSyntaxUid = "0002:0010";

  static const String tagSopInstanceUid = "0008:0018";
  static const String tagStudyDate = "0008:0020";
  static const String tagAcquisitionDate = "0008:0022";
  static const String tagContentDate = "0008:0023";
  static const String tagStudyTime = "0008:0030";
  static const String tagAcquisitionTime = "0008:0032";
  static const String tagContentTime = "0008:0033";
  static const String tagAccessionNumber = "0008:0050";
  static const String tagModality = "0008:0060";
  static const String tagRecommendedDisplayFrameRate = "0008:2144";

  static const String tagPatientId = "0010:0020";

  static const String tagSliceThickness = "0018:0050";
  static const String tagKvp = "0018:0060";

  static const String tagStudyInstanceUid = "0020:000D";
  static const String tagSeriesInstanceUid = "0020:000E";
  static const String tagStudyId = "0020:0010";
  static const String tagSeriesNumber = "0020:0011";
  static const String tagInstanceNumber = "0020:0013";
  static const String tagPatientOrientation = "0020:0020";
  static const String tagImagePositionPatient = "0020:0032";
  static const String tagImageOrientationPatient = "0020:0037";
  static const String tagSliceLocation = "0020:1041";

  static const String tagSamplesPerPixel = "0028:0002";
  static const String tagPhotometricInterpretation = "0028:0004";
  static const String tagNumberOfFrames = "0028:0008";
  static const String tagRows = "0028:0010";
  static const String tagColumns = "0028:0011";
  static const String tagBitsAllocated = "0028:0100";
  static const String tagBitsStored = "0028:0101";
  static const String tagHighBit = "0028:0102";
  static const String tagPixelRepresentation = "0028:0103";
  static const String tagWindowCenter = "0028:1050";
  static const String tagWindowWidth = "0028:1051";
  static const String tagRescaleIntercept = "0028:1052";
  static const String tagRescaleSlope = "0028:1053";
  static const String tagRedPaletteColorLookupTableDescriptor = "0028:1101";
  static const String tagGreenPaletteColorLookupTableDescriptor = "0028:1102";
  static const String tagBluePaletteColorLookupTableDescriptor = "0028:1103";
}
