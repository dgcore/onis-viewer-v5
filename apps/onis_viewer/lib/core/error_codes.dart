/// Error codes matching the ONIS server error codes (EOS_*)
/// These correspond to the error codes defined in onis_kit/include/core/result.hpp
class OnisErrorCodes {
  OnisErrorCodes._(); // Prevent instantiation

  // General errors
  static const int none = 0;
  static const int param = 1;
  static const int canceled = 2;
  static const int memory = 3;
  static const int permission = 4;
  static const int notAvailable = 5;

  // Network errors (17-25)
  static const int networkReceive = 17;
  static const int networkClosed = 19;
  static const int networkConnection = 20;
  static const int networkSsl = 21;
  static const int networkSend = 22;
  static const int networkUnknownCmd = 23;
  static const int networkDatagram = 24;
  static const int urlResolve = 25;

  static const int targetNetworkConnection = 32;

  // Database errors (50-58)
  static const int dbConnection = 50;
  static const int dbQuery = 51;
  static const int dbNull = 52;
  static const int dbValue = 53;
  static const int dbValueLength = 54;
  static const int dbTransaction = 55;
  static const int dbTransactionCommit = 56;
  static const int dbConsistency = 57;
  static const int dbUpdate = 58;

  // Other errors (100+)
  static const int unknown = 100;
  static const int internal = 101;
  static const int resource = 103;
  static const int noSupport = 104;
  static const int notFound = 105;
  static const int allFailed = 106;
  static const int someFailure = 107;
  static const int duplicate = 108;
  static const int busy = 109;
  static const int overflow = 110;
  static const int invalidResponse = 111;
  static const int logicError = 112;

  // Timeout
  static const int timeout = 400;

  // Authentication/Authorization errors (500+)
  static const int invalidUser = 500;
  static const int invalidSession = 502;
  static const int targetPermission = 505;
  static const int sessionExceededLimit = 506;
  static const int invalidCsrf = 508;

  // Media errors (524+)
  static const int media = 524;
  static const int noFile = 525;
  static const int fileWrite = 526;
  static const int fileRead = 527;
  static const int fileOpen = 528;
  static const int fileFormat = 529;
  static const int fileCreate = 530;
  static const int fileMissing = 531;
  static const int fileConversion = 532;
  static const int invalidStream = 533;
  static const int fileRename = 534;
  static const int fileCopy = 535;
  static const int fileMove = 536;
  static const int fileSize = 537;
  static const int endOfFile = 538;
  static const int fileDelete = 539;

  // Input charset
  static const int inputCharset = 550;

  // Directory errors
  static const int dirCreate = 550;
  static const int dirDelete = 551;
  static const int dirRename = 552;
  static const int dirOpen = 553;

  // DICOM tag errors (600+)
  static const int tagValueInvalidWithDefaultRepertoire = 600;
  static const int tagNameConflict = 601;
  static const int tagInsert = 602;
  static const int tagNoCompatibleRepertoire = 603;
  static const int tagUnsupportedRepertoire = 604;
  static const int anonymizeTag = 610;

  // DICOM errors (700+)
  static const int invalidDcm = 700;
  static const int missingSopUid = 701;
  static const int missingSeriesUid = 702;
  static const int missingStudyUid = 703;
  static const int missingModality = 704;
  static const int missingPatientId = 705;
  static const int extractFrame = 706;
  static const int changeTransfer = 708;
  static const int sopclassNotSupported = 709;
  static const int failedToStore = 710;
  static const int conflict = 712;
  static const int addDicomDir = 714;
  static const int createDicomDir = 715;
  static const int writeDicomDir = 716;
  static const int createDicomFile = 717;
  static const int dcmCharset = 718;

  // DICOM AE errors (800+)
  static const int aeRejection = 800;
  static const int destination = 801;

  // Image errors (900+)
  static const int invalidPalette = 900;
  static const int invalidImage = 901;
  static const int failedToExtractImage = 902;
  static const int noImage = 903;

  // Circular reference
  static const int circular = 999;

  // Zip errors (1000+)
  static const int zipCreate = 1001;
  static const int zipAddFile = 1002;
  static const int zipSourceFile = 1003;

  // Recording errors (2000+)
  static const int missingRecordingPlan = 2000;
  static const int notCapturing = 2021;
  static const int startPlaying = 2050;
  static const int startStreaming = 2060;
  static const int signalLost = 2061;

  // Exam errors (2100+)
  static const int examMissing = 2100;
  static const int wrongExam = 2101;
  static const int noExamSession = 2102;
  static const int alreadyRecording = 2103;
  static const int startRecording = 2104;

  // RS232 errors
  static const int rs232 = 2150;

  // Request errors (2200+)
  static const int invalidRequest = 2200;
  static const int notReady = 2201;
  static const int mediaClosed = 2202;

  // Decoding errors (2400+)
  static const int decoding = 2400;
  static const int seek = 2401;

  // Capacity errors (2500+)
  static const int capacityOver = 2500;
  static const int frameRateConflict = 2501;
  static const int encoding = 2502;

  // USB errors (2600+)
  static const int usbDriveNotFound = 2600;
  static const int usbMultipleDrives = 2601;
  static const int usbUnmountFailed = 2602;

  /// Check if an integer value is a valid error code
  /// Returns true if the value matches any known error code constant
  static bool isValid(int value) {
    // Check against all known error codes
    return value == none ||
        value == param ||
        value == canceled ||
        value == memory ||
        value == permission ||
        value == notAvailable ||
        value == networkReceive ||
        value == networkClosed ||
        value == networkConnection ||
        value == networkSsl ||
        value == networkSend ||
        value == networkUnknownCmd ||
        value == networkDatagram ||
        value == urlResolve ||
        value == targetNetworkConnection ||
        value == dbConnection ||
        value == dbQuery ||
        value == dbNull ||
        value == dbValue ||
        value == dbValueLength ||
        value == dbTransaction ||
        value == dbTransactionCommit ||
        value == dbConsistency ||
        value == dbUpdate ||
        value == unknown ||
        value == internal ||
        value == resource ||
        value == noSupport ||
        value == notFound ||
        value == allFailed ||
        value == someFailure ||
        value == duplicate ||
        value == busy ||
        value == overflow ||
        value == invalidResponse ||
        value == logicError ||
        value == timeout ||
        value == invalidUser ||
        value == invalidSession ||
        value == targetPermission ||
        value == sessionExceededLimit ||
        value == invalidCsrf ||
        value == media ||
        value == noFile ||
        value == fileWrite ||
        value == fileRead ||
        value == fileOpen ||
        value == fileFormat ||
        value == fileCreate ||
        value == fileMissing ||
        value == fileConversion ||
        value == invalidStream ||
        value == fileRename ||
        value == fileCopy ||
        value == fileMove ||
        value == fileSize ||
        value == endOfFile ||
        value == fileDelete ||
        value == inputCharset ||
        value == dirCreate ||
        value == dirDelete ||
        value == dirRename ||
        value == dirOpen ||
        value == tagValueInvalidWithDefaultRepertoire ||
        value == tagNameConflict ||
        value == tagInsert ||
        value == tagNoCompatibleRepertoire ||
        value == tagUnsupportedRepertoire ||
        value == anonymizeTag ||
        value == invalidDcm ||
        value == missingSopUid ||
        value == missingSeriesUid ||
        value == missingStudyUid ||
        value == missingModality ||
        value == missingPatientId ||
        value == extractFrame ||
        value == changeTransfer ||
        value == sopclassNotSupported ||
        value == failedToStore ||
        value == conflict ||
        value == addDicomDir ||
        value == createDicomDir ||
        value == writeDicomDir ||
        value == createDicomFile ||
        value == dcmCharset ||
        value == aeRejection ||
        value == destination ||
        value == invalidPalette ||
        value == invalidImage ||
        value == failedToExtractImage ||
        value == noImage ||
        value == circular ||
        value == zipCreate ||
        value == zipAddFile ||
        value == zipSourceFile ||
        value == missingRecordingPlan ||
        value == notCapturing ||
        value == startPlaying ||
        value == startStreaming ||
        value == signalLost ||
        value == examMissing ||
        value == wrongExam ||
        value == noExamSession ||
        value == alreadyRecording ||
        value == startRecording ||
        value == rs232 ||
        value == invalidRequest ||
        value == notReady ||
        value == mediaClosed ||
        value == decoding ||
        value == seek ||
        value == capacityOver ||
        value == frameRateConflict ||
        value == encoding ||
        value == usbDriveNotFound ||
        value == usbMultipleDrives ||
        value == usbUnmountFailed;
  }
}
