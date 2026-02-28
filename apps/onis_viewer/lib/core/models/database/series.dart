import '../../../utils/date.dart';

/// Series model for database management
class Series {
  // Flag constants matching C++ implementation
  static const int infoSeriesCharacterSet = 2;
  static const int infoSeriesNum = 4;
  static const int infoSeriesDescription = 8;
  static const int infoSeriesBodyPart = 16;
  static const int infoSeriesDate = 32;
  static const int infoSeriesIcon = 64;
  static const int infoSeriesProperties = 256;
  static const int infoSeriesTransferSyntax = 1024;
  static const int infoSeriesStatistics = 2048;
  static const int infoSeriesCreation = 4096;
  static const int infoSeriesStatus = 8192;
  static const int infoSeriesModality = 16384;
  static const int infoSeriesStation = 32768;

  /// Flags indicating which fields are valid/present
  int flags;

  String uid = '';
  String charset = '';
  String modality = '';
  String seriesNum = '';
  String description = '';
  String bodyPart = '';
  String station = '';
  DateTime? date;
  bool haveIcon = false;
  int iconMedia = 0;
  String iconPath = '';
  bool haveProperties = false;
  int propertyMedia = 0;
  String propertyPath = '';
  String transferSyntax = '';
  int imcnt = 0;
  int status = 0;
  DateTime? crdate;

  Series({
    this.flags = 0,
    this.uid = '',
    this.charset = '',
    this.modality = '',
    this.seriesNum = '',
    this.description = '',
    this.bodyPart = '',
    this.station = '',
    this.date,
    this.haveIcon = false,
    this.iconMedia = 0,
    this.iconPath = '',
    this.haveProperties = false,
    this.propertyMedia = 0,
    this.propertyPath = '',
    this.transferSyntax = '',
    this.imcnt = 0,
    this.status = 0,
    this.crdate,
  });

  /// Check if a specific flag is set
  bool hasFlag(int flag) => (flags & flag) != 0;

  /// Check if charset field is valid
  bool get hasCharacterSet => hasFlag(infoSeriesCharacterSet);

  /// Check if series number field is valid
  bool get hasSeriesNum => hasFlag(infoSeriesNum);

  /// Check if description field is valid
  bool get hasDescription => hasFlag(infoSeriesDescription);

  /// Check if body part field is valid
  bool get hasBodyPart => hasFlag(infoSeriesBodyPart);

  /// Check if date field is valid
  bool get hasDate => hasFlag(infoSeriesDate);

  /// Check if icon field is valid
  bool get hasIcon => hasFlag(infoSeriesIcon);

  /// Check if properties field is valid
  bool get hasProperties => hasFlag(infoSeriesProperties);

  /// Check if transfer syntax field is valid
  bool get hasTransferSyntax => hasFlag(infoSeriesTransferSyntax);

  /// Check if statistics field is valid
  bool get hasStatistics => hasFlag(infoSeriesStatistics);

  /// Check if creation field is valid
  bool get hasCreation => hasFlag(infoSeriesCreation);

  /// Check if status field is valid
  bool get hasStatus => hasFlag(infoSeriesStatus);

  /// Check if modality field is valid
  bool get hasModality => hasFlag(infoSeriesModality);

  /// Check if station field is valid
  bool get hasStation => hasFlag(infoSeriesStation);

  /// Create a Study from a JSON map (for JSON deserialization)
  factory Series.fromJson(Map<String, dynamic> json) {
    // Read flags from JSON (default to 0 if not present)
    final flags = (json['flags'] as num?)?.toInt() ?? 0;

    // Parse crdate (ISO 8601 format expected) - may be null if not defined
    DateTime? crdate;
    if ((flags & infoSeriesCreation) != 0) {
      try {
        crdate = DateTime.parse(json['crdate'] as String);
      } catch (e) {
        crdate = null; // Leave as null if parsing fails
      }
    }

    // Parse series date and time using DICOM format (YYYYMMDD and HHMMSS.XXX)
    DateTime? seriesDate;
    if ((flags & infoSeriesDate) != 0) {
      final seriesDateStr = json['date'] as String?;
      final seriesTimeStr = json['time'] as String?;
      if (seriesDateStr != null && seriesDateStr.isNotEmpty) {
        seriesDate = createDateTimeFromDicom(seriesDateStr, seriesTimeStr);
      }
    }

    return Series(
      flags: flags,
      uid: json['uid'] as String? ?? '',
      crdate: crdate,
      modality: json['modality'] as String? ?? '',
      seriesNum: json['seriesNum'] as String? ?? '',
      description: json['description'] as String? ?? '',
      bodyPart: json['bodyPart'] as String? ?? '',
      station: json['station'] as String? ?? '',
      date: seriesDate,
      haveIcon: json['haveIcon'] as bool? ?? false,
      iconMedia: json['iconMedia'] as int? ?? 0,
      iconPath: json['iconPath'] as String? ?? '',
      haveProperties: json['haveProperties'] as bool? ?? false,
      propertyMedia: json['propertyMedia'] as int? ?? 0,
      propertyPath: json['propertyPath'] as String? ?? '',
      transferSyntax: json['transferSyntax'] as String? ?? '',
      imcnt: json['imcnt'] as int? ?? 0,
      status: json['status'] as int? ?? 0,
    );
  }
}
