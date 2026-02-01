/// Study model for database management
class Study {
  // Flag constants matching C++ implementation
  static const int infoStudyCharacterSet = 2;
  static const int infoStudyModalities = 4;
  static const int infoStudyAccnum = 8;
  static const int infoStudyId = 16;
  static const int infoStudyDescription = 32;
  static const int infoStudyBodyParts = 64;
  static const int infoStudyAge = 128;
  static const int infoStudyDate = 256;
  static const int infoStudyStatistics = 1024;
  static const int infoStudyCreation = 2048;
  static const int infoStudyStatus = 4096;
  static const int infoStudyReportStatus = 8192;
  static const int infoStudyComment = 16384;
  static const int infoStudyInstitution = 32768;
  static const int infoStudyStations = 65536;
  static const int infoAll = 0xFFFFFFFF;

  /// Flags indicating which fields are valid/present
  int flags;

  String sourceUid;
  String id; // seq
  String uid;
  String charset;
  String? studyDate; // date (YYYYMMDD)
  String? studyTime; // time
  String modalities;
  String bodyParts;
  String accnum;
  String studyId;
  String desc;
  String age;
  String institution;
  String comment;
  String stations;
  int srcnt;
  int imcnt;
  int rptcnt;
  int status;
  String conflict;
  DateTime? crdate;
  String originId;
  String originName;
  String originIp;

  Study({
    this.flags = 0,
    this.sourceUid = '',
    this.id = '',
    this.uid = '',
    this.charset = '',
    this.studyDate,
    this.studyTime,
    this.modalities = '',
    this.bodyParts = '',
    this.accnum = '',
    this.studyId = '',
    this.desc = '',
    this.age = '',
    this.institution = '',
    this.comment = '',
    this.stations = '',
    this.srcnt = 0,
    this.imcnt = 0,
    this.rptcnt = 0,
    this.status = 0,
    this.conflict = '',
    this.crdate,
    this.originId = '',
    this.originName = '',
    this.originIp = '',
  });

  /// Check if a specific flag is set
  bool hasFlag(int flag) => (flags & flag) != 0;

  /// Check if charset field is valid
  bool get hasCharacterSet => hasFlag(infoStudyCharacterSet);

  /// Check if modalities field is valid
  bool get hasModalities => hasFlag(infoStudyModalities);

  /// Check if accnum field is valid
  bool get hasAccnum => hasFlag(infoStudyAccnum);

  /// Check if study_id field is valid
  bool get hasStudyId => hasFlag(infoStudyId);

  /// Check if description field is valid
  bool get hasDescription => hasFlag(infoStudyDescription);

  /// Check if body parts field is valid
  bool get hasBodyParts => hasFlag(infoStudyBodyParts);

  /// Check if age field is valid
  bool get hasAge => hasFlag(infoStudyAge);

  /// Check if date/time fields are valid
  bool get hasDate => hasFlag(infoStudyDate);

  /// Check if statistics fields are valid
  bool get hasStatistics => hasFlag(infoStudyStatistics);

  /// Check if creation fields are valid
  bool get hasCreation => hasFlag(infoStudyCreation);

  /// Check if status field is valid
  bool get hasStatus => hasFlag(infoStudyStatus);

  /// Check if report status field is valid
  bool get hasReportStatus => hasFlag(infoStudyReportStatus);

  /// Check if comment field is valid
  bool get hasComment => hasFlag(infoStudyComment);

  /// Check if institution field is valid
  bool get hasInstitution => hasFlag(infoStudyInstitution);

  /// Check if stations field is valid
  bool get hasStations => hasFlag(infoStudyStations);

  /// Create a Study from a JSON map (for JSON deserialization)
  factory Study.fromJson(Map<String, dynamic> json, {String? sourceUid}) {
    // Read flags from JSON (default to 0 if not present)
    final flags = (json['flags'] as num?)?.toInt() ?? 0;

    // Parse study date (format: YYYYMMDD) - may be null if not defined
    String? studyDate;
    if ((flags & infoStudyDate) != 0) {
      studyDate = json['date'] as String?;
    }

    // Parse study time - may be null if not defined
    String? studyTime;
    if ((flags & infoStudyDate) != 0) {
      studyTime = json['time'] as String?;
    }

    // Parse crdate (ISO 8601 format expected) - may be null if not defined
    DateTime? crdate;
    if ((flags & infoStudyCreation) != 0) {
      try {
        crdate = DateTime.parse(json['crdate'] as String);
      } catch (e) {
        crdate = null; // Leave as null if parsing fails
      }
    }

    return Study(
      flags: flags,
      sourceUid: sourceUid ?? json['sourceUid'] as String? ?? '',
      id: json['seq'] as String? ?? json['id'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      charset: (flags & infoStudyCharacterSet) != 0
          ? (json['charset'] as String? ?? '')
          : '',
      studyDate: studyDate,
      studyTime: studyTime,
      modalities: (flags & infoStudyModalities) != 0
          ? (json['modalities'] as String? ?? '')
          : '',
      bodyParts: (flags & infoStudyBodyParts) != 0
          ? (json['bodyparts'] as String? ?? '')
          : '',
      accnum: (flags & infoStudyAccnum) != 0
          ? (json['accnum'] as String? ?? '')
          : '',
      studyId:
          (flags & infoStudyId) != 0 ? (json['study_id'] as String? ?? '') : '',
      desc: (flags & infoStudyDescription) != 0
          ? (json['desc'] as String? ?? '')
          : '',
      age: (flags & infoStudyAge) != 0 ? (json['age'] as String? ?? '') : '',
      institution: (flags & infoStudyInstitution) != 0
          ? (json['institution'] as String? ?? '')
          : '',
      comment: (flags & infoStudyComment) != 0
          ? (json['comment'] as String? ?? '')
          : '',
      stations: (flags & infoStudyStations) != 0
          ? (json['stations'] as String? ?? '')
          : '',
      srcnt: (flags & infoStudyStatistics) != 0
          ? ((json['srcnt'] as num?)?.toInt() ?? 0)
          : 0,
      imcnt: (flags & infoStudyStatistics) != 0
          ? ((json['imcnt'] as num?)?.toInt() ?? 0)
          : 0,
      rptcnt: (flags & infoStudyStatistics) != 0
          ? ((json['rptcnt'] as num?)?.toInt() ?? 0)
          : 0,
      status: (flags & infoStudyStatus) != 0
          ? ((json['status'] as num?)?.toInt() ?? 0)
          : 0,
      conflict: (flags & infoStudyStatus) != 0
          ? (json['conflict'] as String? ?? '')
          : '',
      crdate: crdate,
      originId: (flags & infoStudyCreation) != 0
          ? (json['oid'] as String? ?? json['originId'] as String? ?? '')
          : '',
      originName: (flags & infoStudyCreation) != 0
          ? (json['oname'] as String? ?? json['originName'] as String? ?? '')
          : '',
      originIp: (flags & infoStudyCreation) != 0
          ? (json['oip'] as String? ?? json['originIp'] as String? ?? '')
          : '',
    );
  }
}
