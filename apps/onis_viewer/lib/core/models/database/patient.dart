import '../../../utils/date.dart';

class Patient {
  // Flag constants
  static const int infoPatientCharset = 1;
  static const int infoPatientName = 2;
  static const int infoPatientBirthdate = 4;
  static const int infoPatientSex = 8;
  static const int infoPatientStatistics = 16;
  static const int infoPatientStatus = 32;
  static const int infoPatientCreation = 64;
  static const int infoAll = 0xFFFFFFFF;

  /// Flags indicating which fields are valid/present
  int flags;
  String sourceUid;
  String id;
  String pid;
  String name;
  String ideogram;
  String phonetic;
  String charset;
  DateTime? birthDate;
  String sex;
  int stcnt;
  int srcnt;
  int imcnt;
  int status;
  DateTime? crdate;
  String originId;
  String originName;
  String originIp;

  Patient({
    this.flags = 0,
    this.sourceUid = '',
    this.id = '',
    this.pid = '',
    this.name = '',
    this.ideogram = '',
    this.phonetic = '',
    this.charset = '',
    this.birthDate,
    this.sex = '',
    this.stcnt = 0,
    this.srcnt = 0,
    this.imcnt = 0,
    this.status = 0,
    this.crdate,
    this.originId = '',
    this.originName = '',
    this.originIp = '',
  });

  /// Check if a specific flag is set
  bool hasFlag(int flag) => (flags & flag) != 0;

  /// Check if charset field is valid
  bool get hasCharset => hasFlag(infoPatientCharset);

  /// Check if name fields are valid
  bool get hasName => hasFlag(infoPatientName);

  /// Check if birthdate field is valid
  bool get hasBirthdate => hasFlag(infoPatientBirthdate);

  /// Check if sex field is valid
  bool get hasSex => hasFlag(infoPatientSex);

  /// Check if statistics fields are valid
  bool get hasStatistics => hasFlag(infoPatientStatistics);

  /// Check if status field is valid
  bool get hasStatus => hasFlag(infoPatientStatus);

  /// Check if creation fields are valid
  bool get hasCreation => hasFlag(infoPatientCreation);

  /// Create a Patient from a JSON map (for JSON deserialization)
  factory Patient.fromJson(Map<String, dynamic> json, {String? sourceUid}) {
    // Read flags from JSON (default to 0 if not present)
    final flags = (json['flags'] as num?)?.toInt() ?? 0;

    // Parse birthdate using DICOM format (YYYYMMDD and optional HHMMSS.XXX)
    DateTime? birthDate;
    if ((flags & infoPatientBirthdate) != 0) {
      final birthdateStr = json['birthdate'] as String?;
      final birthtimeStr = json['birthtime'] as String?;
      if (birthdateStr != null && birthdateStr.isNotEmpty) {
        birthDate =
            DateUtils.createDateTimeFromDicom(birthdateStr, birthtimeStr);
      }
    }

    // Parse crdate (ISO 8601 format expected) - may be null if not defined
    DateTime? crdate;
    if ((flags & infoPatientCreation) != 0) {
      try {
        crdate = DateTime.parse(json['crdate'] as String);
      } catch (e) {
        crdate = null; // Leave as null if parsing fails
      }
    }

    return Patient(
      flags: flags,
      sourceUid: json['sourceUid'] as String? ?? sourceUid ?? '',
      id: json['seq'] as String? ?? '',
      pid: json['pid'] as String? ?? json['uid'] as String? ?? '',
      name:
          (flags & infoPatientName) != 0 ? (json['name'] as String? ?? '') : '',
      ideogram: (flags & infoPatientName) != 0
          ? (json['ideogram'] as String? ?? '')
          : '',
      phonetic: (flags & infoPatientName) != 0
          ? (json['phonetic'] as String? ?? '')
          : '',
      charset: (flags & infoPatientCharset) != 0
          ? (json['charset'] as String? ?? '')
          : '',
      birthDate: birthDate,
      sex: (flags & infoPatientSex) != 0 ? (json['sex'] as String? ?? '') : '',
      stcnt: (flags & infoPatientStatistics) != 0
          ? ((json['stcnt'] as num?)?.toInt() ?? 0)
          : 0,
      srcnt: (flags & infoPatientStatistics) != 0
          ? ((json['srcnt'] as num?)?.toInt() ?? 0)
          : 0,
      imcnt: (flags & infoPatientStatistics) != 0
          ? ((json['imcnt'] as num?)?.toInt() ?? 0)
          : 0,
      status: (flags & infoPatientStatus) != 0
          ? ((json['status'] as num?)?.toInt() ?? 0)
          : 0,
      crdate: crdate,
      originId: (flags & infoPatientCreation) != 0
          ? (json['oid'] as String? ?? json['originId'] as String? ?? '')
          : '',
      originName: (flags & infoPatientCreation) != 0
          ? (json['oname'] as String? ?? json['originName'] as String? ?? '')
          : '',
      originIp: (flags & infoPatientCreation) != 0
          ? (json['oip'] as String? ?? json['originIp'] as String? ?? '')
          : '',
    );
  }

  /// JSON shape matches [fromJson] (API / local persistence).
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'flags': flags,
      'seq': id,
      'pid': pid,
      'uid': pid,
      'sourceUid': sourceUid,
      'name': name,
      'ideogram': ideogram,
      'phonetic': phonetic,
      'charset': charset,
      'sex': sex,
      'stcnt': stcnt,
      'srcnt': srcnt,
      'imcnt': imcnt,
      'status': status,
      'originId': originId,
      'originName': originName,
      'originIp': originIp,
    };
    if ((flags & infoPatientBirthdate) != 0 && birthDate != null) {
      json['birthdate'] = _patientToDicomDate(birthDate!);
      final time = _patientToDicomTime(birthDate!);
      if (time != null) {
        json['birthtime'] = time;
      }
    }
    if ((flags & infoPatientCreation) != 0 && crdate != null) {
      json['crdate'] = crdate!.toIso8601String();
    }
    return json;
  }
}

String _patientToDicomDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

String? _patientToDicomTime(DateTime d) {
  if (d.hour == 0 && d.minute == 0 && d.second == 0 && d.millisecond == 0) {
    return null;
  }
  return '${d.hour.toString().padLeft(2, '0')}${d.minute.toString().padLeft(2, '0')}${d.second.toString().padLeft(2, '0')}.${d.millisecond.toString().padLeft(3, '0')}';
}
