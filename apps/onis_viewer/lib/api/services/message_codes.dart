class OSMSG {
  OSMSG._(); // Prevent instantiation

  static const int seriesDownloadReceivedInfo = 1;
  static const int imageContainerModified = 2;
  static const int seriesImagesReceived = 3;
  static const int seriesImagesDownloadCompleted = 4;

  static const int imageContainerToolVisibility = 5;
  static const int imageContainerToolSet = 6;

  static const int pageTypeRegistered = 7;
  static const int pageTypeUnregistered = 8;
  static const int openedPatientsSnapshot = 9;
  static const int openedPatientsSyncRequest = 10;
}
