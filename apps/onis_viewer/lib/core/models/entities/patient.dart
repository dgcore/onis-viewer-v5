import 'package:onis_viewer/core/dicom/image_region.dart';
import 'package:onis_viewer/core/graphics/math/matrix.dart';
import 'package:onis_viewer/core/models/database/image.dart' as database;
import 'package:onis_viewer/core/models/database/patient.dart' as database;
import 'package:onis_viewer/core/models/database/series.dart' as database;
import 'package:onis_viewer/core/models/database/study.dart' as database;
import 'package:onis_viewer/core/result/result.dart';
import 'package:uuid_v4/uuid_v4.dart';

/// Sort constants for studies
class OsSort {
  static const int sortByAccnum = 0;
  static const int sortByDate = 1;
  static const int sortBySeriesNum = 2;
}

///////////////////////////////////////////////////////////////////////
// OsImageDicomInfo
///////////////////////////////////////////////////////////////////////

class ImageDicomInfo {
  bool loaded = false;
  int instanceNum = 0x7FFFFFFF;
  double width = 0; //image width in pixel;
  double height = 0; //image height in pixel;
  String sop = '';
  String modality = '';
  ImageRegionInfo? regionInfo;
  double originalSliceLocation = double.infinity;
  double calibratedSliceLocation = double.infinity;
  OsMatrix? originalImageOrientationMatrix; //original image orientation matrix
  OsMatrix? calibratedImageOrientationMatrix; //calibrated image orientation
  DateTime? acquisitionDate;
  DateTime? imageDateTime;

  void copyFrom(ImageDicomInfo other) {
    //console.log("do we need to copy the sop and modality?????")
    loaded = other.loaded;
    instanceNum = other.instanceNum;
    width = other.width;
    height = other.height;
    originalSliceLocation = other.originalSliceLocation;
    if (other.calibratedImageOrientationMatrix != null) {
      calibratedImageOrientationMatrix ??= OsMatrix();
      calibratedImageOrientationMatrix!
          .copyFrom(other.calibratedImageOrientationMatrix!);
    }
    if (other.originalImageOrientationMatrix != null) {
      originalImageOrientationMatrix ??= OsMatrix();
      originalImageOrientationMatrix!
          .copyFrom(other.originalImageOrientationMatrix!);
    }
    calibratedSliceLocation = other.calibratedSliceLocation;

    regionInfo = null;
    if (other.regionInfo != null) regionInfo = other.regionInfo!.clone();
    imageDateTime = other.imageDateTime != null
        ? DateTime.fromMillisecondsSinceEpoch(
            other.imageDateTime!.millisecondsSinceEpoch)
        : null;

    acquisitionDate = other.acquisitionDate != null
        ? DateTime.fromMillisecondsSinceEpoch(
            other.acquisitionDate!.millisecondsSinceEpoch)
        : null;
  }
}

/// Opened patient entity with studies
class Patient {
  database.Patient? _patient;
  final List<Study> _studies = [];

  // Getters
  database.Patient? get databaseInfo => _patient;
  List<Study> get studies => List.unmodifiable(_studies);
  String? get sourceUid {
    return _patient?.sourceUid;
  }

  // Setters
  set databaseInfo(database.Patient? patient) {
    if (patient == _patient) return;
    _patient = patient;
  }

  /// Get sorted studies
  void getSortedStudies(List<Study> studies, int orderBy, bool ascending) {
    studies.addAll(_studies);
    if (orderBy == OsSort.sortByAccnum) {
      studies.sort((a, b) {
        int ret = 0;
        final dba = a.databaseInfo;
        final dbb = b.databaseInfo;
        if (dba != null && dbb != null) {
          if (dba.accnum.isNotEmpty && dbb.accnum.isNotEmpty) {
            final sra = int.tryParse(dba.accnum) ?? 0;
            final srb = int.tryParse(dbb.accnum) ?? 0;
            if (sra < srb) {
              ret = -1;
            } else if (sra > srb) {
              ret = 1;
            }
          } else if (dba.accnum.isNotEmpty && dbb.accnum.isEmpty) {
            ret = 1;
          } else if (dba.accnum.isEmpty && dbb.accnum.isNotEmpty) {
            ret = -1;
          }
        } else if (dba != null) {
          ret = 1;
        } else if (dbb != null) {
          ret = -1;
        }
        if (!ascending) ret = -ret;
        return ret;
      });
    } else if (orderBy == OsSort.sortByDate) {
      studies.sort((a, b) {
        int ret = 0;
        final dba = a.databaseInfo;
        final dbb = b.databaseInfo;
        if (dba != null && dbb != null) {
          // studyDate is a String in format YYYYMMDD, so we can compare directly
          if (dba.studyDate != null &&
              dba.studyDate!.isNotEmpty &&
              dbb.studyDate != null &&
              dbb.studyDate!.isNotEmpty) {
            final dateA = dba.studyDate!;
            final dateB = dbb.studyDate!;
            final comparison = dateA.compareTo(dateB);
            if (comparison < 0) {
              ret = -1;
            } else if (comparison > 0) {
              ret = 1;
            }
          } else if (dba.studyDate != null &&
              dba.studyDate!.isNotEmpty &&
              (dbb.studyDate == null || dbb.studyDate!.isEmpty)) {
            ret = 1;
          } else if ((dba.studyDate == null || dba.studyDate!.isEmpty) &&
              dbb.studyDate != null &&
              dbb.studyDate!.isNotEmpty) {
            ret = -1;
          }
        } else if (dba != null) {
          ret = 1;
        } else if (dbb != null) {
          ret = -1;
        }
        if (!ascending) ret = -ret;
        return ret;
      });
    }
  }

  /// Add a study
  void addStudy(Study study) {
    if (_studies.contains(study)) return;
    _studies.add(study);
    study._wPatient = WeakReference(this);
  }

  /// Remove a study
  void removeStudy(Study study) {
    final index = _studies.indexOf(study);
    if (index >= 0) {
      _studies.removeAt(index);
      study._wPatient = null;
    }
  }

  /// Find study by GUID
  Study? findStudyByGuid(String guid) {
    for (final study in _studies) {
      if (study.guid == guid) {
        return study;
      }
    }
    return null;
  }
}

/// Opened study entity with series and reports
class Study {
  database.Study? _study;
  WeakReference<Patient>? _wPatient;
  final List<Series> _series = []; // Series not yet implemented
  // final List<Report> _reports = []; // Reports not yet implemented
  String guid = UUIDv4().toString();

  // Getters:
  database.Study? get databaseInfo => _study;
  Patient? get patient => _wPatient?.target;
  List<Series> get series => List.unmodifiable(_series);
  String? get sourceUid => patient?.sourceUid;

  // Setters:
  set databaseInfo(database.Study? study) {
    if (study == _study) return;
    _study = study;
  }

  set patient(Patient? newPatient) {
    if (patient == newPatient) return;
    patient?.removeStudy(this);
    if (newPatient != null) newPatient.addStudy(this);
  }

  /// Add a series
  void addSeries(Series series) {
    if (_series.contains(series)) return;
    _series.add(series);
    series._wStudy = WeakReference(this);
  }

  /// Remove a series
  void removeSeries(Series series) {
    final index = _series.indexOf(series);
    if (index >= 0) {
      _series.removeAt(index);
      series._wStudy = null;
    }
  }

  /// Update modalities and body parts from series
  void updateModalitiesAndBodyParts() {
    final modalities = <String>[];
    final bodyParts = <String>[];

    // TODO: Implement when Series is available
    // for (final series in _series) {
    //   final dbSeries = series.getDatabaseInfo();
    //   if (dbSeries != null) {
    //     if (dbSeries.modality.isNotEmpty &&
    //         !modalities.contains(dbSeries.modality)) {
    //       modalities.add(dbSeries.modality);
    //     }
    //     if (dbSeries.bodyPart.isNotEmpty &&
    //         !bodyParts.contains(dbSeries.bodyPart)) {
    //       bodyParts.add(dbSeries.bodyPart);
    //     }
    //   }
    // }

    modalities.sort();
    bodyParts.sort();
    final dbStudy = databaseInfo;
    if (dbStudy != null) {
      dbStudy.modalities = modalities.join(', ');
      dbStudy.bodyParts = bodyParts.join(', ');
    }
  }
}

/// Opened study entity with series and reports
class Series {
  String guid = UUIDv4().toString();
  database.Series? _series;
  WeakReference<Study>? _wStudy;
  final List<Image> images = [];
  OsResult loadStatus = OsResult();

  Series() {
    loadStatus.status = ResultStatus.pending;
  }
  // Getters:
  database.Series? get databaseInfo => _series;
  Study? get study => _wStudy?.target;
  String? get sourceUid => study?.sourceUid;

  // Setters:
  set databaseInfo(database.Series? series) {
    if (series == _series) return;
    _series = series;
  }

  set study(Study? newStudy) {
    if (study == newStudy) return;
    study?.removeSeries(this);
    if (newStudy != null) newStudy.addSeries(this);
  }

  /// Add image
  void addImage(Image image) {
    if (images.contains(image)) return;
    images.add(image);
    image._wSeries = WeakReference(this);
  }

  // Operations:
  void prepareForDownload(int imageCount) {
    if (imageCount > images.length) {
      int count = imageCount - images.length;
      for (int i = 0; i < count; i++) {
        final image = Image();
        image.loadStatus.status = ResultStatus.pending;
        image.loadIndex = images.length;
        addImage(image);
      }
    }
  }
}

///////////////////////////////////////////////////////////////////////
// OsOpenedImage
///////////////////////////////////////////////////////////////////////

class Image {
  //static CURRENT:number = 0;
  //static ORIGINAL:number = 1;
  //static CALIBRATED:number = 2;

  database.Image? _image;
  WeakReference<Series>? _wSeries;
  //final bool _highestQuality = false;
  OsResult loadStatus = OsResult();
  int loadIndex = 0;
  // _dicomInfo:OsImageDicomInfo|null = null;
  //DicomFile? _dcm;
  //final int _frameCount = 0;

  Image() {
    loadStatus.status = ResultStatus.pending;
  }

  // Getters:
  database.Image? get databaseInfo => _image;
  Series? get series => _wSeries?.target;

  // Setters:
  set databaseInfo(database.Image? image) {
    if (image == _image) return;
    _image = image;
  }
}
