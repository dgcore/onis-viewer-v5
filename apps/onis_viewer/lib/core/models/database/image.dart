/// Image model for database management
class Image {
  static const int infoImageCharset = 1;
  static const int infoImageInstanceNumber = 2;
  static const int infoImageAcqNumber = 4;
  static const int infoImageSopClass = 8;
  static const int infoImageDimension = 16;
  static const int infoImageDepth = 32;
  static const int infoImageIcon = 64;
  static const int infoImageIconDetail = 128;
  static const int infoImagePath = 256;
  static const int infoImageCompression = 512;
  static const int infoImageOriginalTransferSyntax = 1024;
  static const int infoImageCreation = 2048;
  static const int infoImageStatus = 4096;
  static const int infoImageStream = 8192;
  static const int infoImageStreamDetail = 16384;

  String uid = '';
  String charset = '';
  int instNum = -1;
  int acqNum = -1;
  String sopClass = '';
  int width = 0;
  int height = 0;
  int depth = 0;
  int status = 0;
  DateTime? crdate;

  Image({
    this.uid = '',
    this.charset = '',
    this.instNum = -1,
    this.acqNum = -1,
    this.sopClass = '',
    this.width = 0,
    this.height = 0,
    this.depth = 0,
    this.status = 0,
    this.crdate,
  });
}
