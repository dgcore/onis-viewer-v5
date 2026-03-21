import 'package:onis_viewer/core/dicom/dicom_file.dart';
import 'package:onis_viewer/core/dicom/dicom_frame.dart';
import 'package:onis_viewer/core/dicom/dicom_tags.dart';
import 'package:onis_viewer/core/dicom/image_region.dart';
import 'package:onis_viewer/core/error_codes.dart';
import 'package:onis_viewer/core/math/matrix.dart';
import 'package:onis_viewer/core/math/vector3d.dart';
import 'package:onis_viewer/core/models/database/image.dart' as database;
import 'package:onis_viewer/core/models/database/patient.dart' as database;
import 'package:onis_viewer/core/models/database/series.dart' as database;
import 'package:onis_viewer/core/models/database/study.dart' as database;
import 'package:onis_viewer/core/result/result.dart';
import 'package:onis_viewer/utils/date.dart';
import 'package:uuid_v4/uuid_v4.dart';

/// Sort constants for studies
class OsSort {
  static const int sortByAccnum = 0;
  static const int sortByDate = 1;
  static const int sortBySeriesNum = 2;
}

enum OrientationType {
  current,
  original,
  calibrated,
}

///////////////////////////////////////////////////////////////////////
// OsImageDicomInfo
///////////////////////////////////////////////////////////////////////

class ImageDicomInfo {
  bool loaded = false;
  int instanceNum = 0x7FFFFFFF;
  int width = 0; //image width in pixel;
  int height = 0; //image height in pixel;
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
  database.Image? _image;
  WeakReference<Series>? _wSeries;
  final bool _highestQuality = false;
  OsResult loadStatus = OsResult();
  int loadIndex = 0;
  DicomFile? _dcm;
  ImageDicomInfo? _dicomInfo;
  int _frameCount = 0;

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

  //-----------------------------------------------------------------------
  //dicom file
  //-----------------------------------------------------------------------

  DicomFile? get dicomFile {
    return _dcm;
  }

  set dicomFile(DicomFile? dcm) {
    if (identical(_dcm, dcm)) return;
    _dcm = dcm;
    _dicomInfo = ImageDicomInfo();
    loadInformationFromDicomFile();
  }

  //-----------------------------------------------------------------------
  //frames
  //-----------------------------------------------------------------------
  int getFrameCount() {
    return _frameCount;
  }

  DicomFrame? extractFrame(int frameIndex, OsResult? result) {
    if (_dcm == null) {
      if (result != null) {
        result.status = ResultStatus.failure;
        result.reason = OnisErrorCodes.noFile;
      }
      return null;
    }
    return _dcm!.extractFrame(frameIndex, result);
  }

  //-----------------------------------------------------------------------
  //properties
  //-----------------------------------------------------------------------

  bool isDicomFileHighestQuality() {
    return _highestQuality;
  }

  String getModality() {
    String ret = '';
    if (_dicomInfo != null && _dicomInfo!.loaded) {
      ret = _dicomInfo!.modality;
    }
    return ret;
  }

  String getSop() {
    String ret = '';
    if (_dicomInfo != null && _dicomInfo!.loaded) {
      ret = _dicomInfo!.sop;
    }
    return ret;
  }

  int getInstanceNumber() {
    int ret = 0x7FFFFFFF;
    if (_dicomInfo != null && _dicomInfo!.loaded) {
      ret = _dicomInfo!.instanceNum;
    }
    return ret;
  }

  DateTime? getAcquisitionDateTime(bool clone) {
    if (_dicomInfo != null && _dicomInfo!.loaded) {
      final DateTime? date = _dicomInfo!.acquisitionDate;
      if (clone) {
        return date != null
            ? DateTime.fromMillisecondsSinceEpoch(date.millisecondsSinceEpoch)
            : null;
      } else {
        return date;
      }
    }
    return null;
  }

  DateTime? getImageDateTime(bool clone) {
    if (_dicomInfo != null && _dicomInfo!.loaded) {
      final DateTime? date = _dicomInfo!.imageDateTime;
      if (clone) {
        return date != null
            ? DateTime.fromMillisecondsSinceEpoch(date.millisecondsSinceEpoch)
            : null;
      } else {
        return date;
      }
    }
    return null;
  }

  double getSlicePosition(OrientationType type) {
    double ret = double.infinity;
    if (_dicomInfo != null && _dicomInfo!.loaded) {
      switch (type) {
        case OrientationType.current:
          return _dicomInfo!.calibratedSliceLocation == double.infinity
              ? _dicomInfo!.originalSliceLocation
              : _dicomInfo!.calibratedSliceLocation;
        case OrientationType.calibrated:
          return _dicomInfo!.calibratedSliceLocation;
        case OrientationType.original:
          return _dicomInfo!.originalSliceLocation;
      }
    }
    return ret;
  }

  ImageRegionInfo? getRegionInfo() {
    ImageRegionInfo? ret;
    if (_dicomInfo != null && _dicomInfo!.loaded) {
      ret = _dicomInfo!.regionInfo;
    }
    return ret;
  }

  bool getRegionsForFrame(DicomFrame frame, List<ImageRegion> list) {
    ImageRegionInfo? info = getRegionInfo();
    if (info != null) {
      (int width, int height)? widthHeight = frame.getDimensions();
      if (widthHeight != null) {
        if (info.dimensions[0] == widthHeight.$1 &&
            info.dimensions[1] == widthHeight.$2) {
          for (int i = 0; i < info.regions.length; i++) {
            list.add(info.regions[i]);
          }
          return false;
        } else {
          if (widthHeight.$1 > 0 &&
              widthHeight.$2 > 0 &&
              info.dimensions[0] > 0 &&
              info.dimensions[1] > 0) {
            double factorx = widthHeight.$1 / info.dimensions[0];
            double factory = widthHeight.$2 / info.dimensions[1];
            for (int i = 0; i < info.regions.length; i++) {
              ImageRegion region = info.regions[i].clone();
              region.originalSpacing[0] /= factorx;
              region.originalSpacing[1] /= factory;
              region.calibratedSpacing[0] /= factorx;
              region.calibratedSpacing[1] /= factory;
              double x0 = region.x0 * factorx;
              double x1 = region.x1 * factorx;
              double y0 = region.y0 * factory;
              double y1 = region.y1 * factory;
              int fx0 = x0.floor();
              int fx1 = x1.floor();
              int fy0 = y0.floor();
              int fy1 = y1.floor();
              if (fx0 > widthHeight.$1 - 1) fx0 = widthHeight.$1 - 1;
              if (fx1 > widthHeight.$1 - 1) fx1 = widthHeight.$1 - 1;
              if (fy0 > widthHeight.$2 - 1) fy0 = widthHeight.$2 - 1;
              if (fy1 > widthHeight.$2 - 1) fy1 = widthHeight.$2 - 1;
              region.x0 = fx0;
              region.x1 = fx1;
              region.y0 = fy0;
              region.y1 = fy1;
              list.add(region);
            }
            return true;
          }
        }
      }
    }
    return false;
  }

  (int width, int height)? getDimensions33() {
    if (_dicomInfo != null && _dicomInfo!.loaded) {
      return (_dicomInfo!.width, _dicomInfo!.height);
    }
    return null;
  }

  //-----------------------------------------------------------------------
  //orientation
  //-----------------------------------------------------------------------

  bool getImageOrientation(OsMatrix mat,
      {OrientationType type = OrientationType.current}) {
    bool ret = false;
    ImageDicomInfo? info = _dicomInfo;
    if (info != null) {
      if (info.loaded) {
        if (type == OrientationType.current) {
          if (info.calibratedImageOrientationMatrix != null) {
            mat.copyFrom(info.calibratedImageOrientationMatrix!);
            ret = true;
          } else if (info.originalImageOrientationMatrix != null) {
            mat.copyFrom(info.originalImageOrientationMatrix!);
            ret = true;
          }
        } else if (type == OrientationType.calibrated) {
          if (info.calibratedImageOrientationMatrix != null) {
            mat.copyFrom(info.calibratedImageOrientationMatrix!);
            ret = true;
          }
        } else if (type == OrientationType.original) {
          if (info.originalImageOrientationMatrix != null) {
            mat.copyFrom(info.originalImageOrientationMatrix!);
            ret = true;
          }
        }
      }
    }
    return ret;
  }

  //-----------------------------------------------------------------------
  //calibration
  //-----------------------------------------------------------------------
  void calibrate(bool calibrate, double sliceLocation, OsMatrix? mat) {
    ImageDicomInfo? info = _dicomInfo;
    if (info != null && info.loaded) {
      if (calibrate) {
        info.calibratedSliceLocation = sliceLocation;
        if (mat != null) {
          info.calibratedImageOrientationMatrix = OsMatrix();
          info.calibratedImageOrientationMatrix!.copyFrom(mat);
        } else {
          info.calibratedImageOrientationMatrix = null;
        }
      } else {
        info.calibratedImageOrientationMatrix = null;
        info.calibratedSliceLocation = double.infinity;
      }
    }
  }

  void loadInformationFromDicomFile() {
    if (_dcm == null || _dicomInfo == null) return;

    //don't test the following line, it does not work for dicom created without file path, like secondary capture files
    //if (_dcm->is_loaded()) {
    _dicomInfo!.loaded = true;
    _dicomInfo!.originalImageOrientationMatrix = null;
    _dicomInfo!.calibratedImageOrientationMatrix = null;
    _dicomInfo!.sop = _dcm!.getStringElement('0008:0018', null, null);
    _dicomInfo!.modality = _dcm!.getStringElement('0008:0060', null, null);
    String str = _dcm!.getStringElement('0020:0013', null, null);
    if (str.isEmpty) {
      _dicomInfo!.instanceNum = 0x7FFFFFFF;
    } else {
      _dicomInfo!.instanceNum = int.parse(str);
    }
    str = _dcm!.getStringElement('0020:1041', null, null);
    if (str.isEmpty) {
      _dicomInfo!.originalSliceLocation = double.infinity;
    } else {
      _dicomInfo!.originalSliceLocation = double.parse(str);
    }

    List<double> position = [0, 0, 0];
    bool haveImagePosition = false;
    str = _dcm!.getStringElement(DicomTags.tagImagePositionPatient, null, null);
    if (str.isNotEmpty) {
      var data = str.split('\\');
      if (data.length == 3) {
        haveImagePosition = true;
        position[0] = double.parse(data[0]);
        position[1] = double.parse(data[1]);
        position[2] = double.parse(data[2]);
      }
    }
    String simageOrientation = _dcm!
        .getStringElement(DicomTags.tagImageOrientationPatient, null, null);
    if (simageOrientation.isNotEmpty) {
      var data = simageOrientation.split('\\');
      if (data.length == 6) {
        List<double> imageOrientation = [0, 0, 0, 0, 0, 0];
        for (int i = 0; i < 6; i++) {
          imageOrientation[i] = double.parse(data[i]);
        }
        int axe = 0;
        double maxValue = imageOrientation[0];
        if (imageOrientation[1].abs() > maxValue.abs()) {
          axe = 1;
          maxValue = imageOrientation[1];
        }
        if (imageOrientation[2].abs() > maxValue.abs()) {
          axe = 2;
          maxValue = imageOrientation[2];
        }
        axe = 0;
        maxValue = imageOrientation[3];
        if (imageOrientation[4].abs() > maxValue.abs()) {
          axe = 1;
          maxValue = imageOrientation[4];
        }
        if (imageOrientation[5].abs() > maxValue.abs()) {
          axe = 2;
          maxValue = imageOrientation[5];
        }
        if (haveImagePosition) {
          _dicomInfo!.originalImageOrientationMatrix = OsMatrix();
          _dicomInfo!.originalImageOrientationMatrix!.mat[0] =
              imageOrientation[0];
          _dicomInfo!.originalImageOrientationMatrix!.mat[1] =
              imageOrientation[1];
          _dicomInfo!.originalImageOrientationMatrix!.mat[2] =
              imageOrientation[2];
          _dicomInfo!.originalImageOrientationMatrix!.mat[4] =
              imageOrientation[3];
          _dicomInfo!.originalImageOrientationMatrix!.mat[5] =
              imageOrientation[4];
          _dicomInfo!.originalImageOrientationMatrix!.mat[6] =
              imageOrientation[5];
          _dicomInfo!.originalImageOrientationMatrix!.mat[12] = position[0];
          _dicomInfo!.originalImageOrientationMatrix!.mat[13] = position[1];
          _dicomInfo!.originalImageOrientationMatrix!.mat[14] = position[2];
          double l1 = OsVec3D.normalizeMatVec(
              _dicomInfo!.originalImageOrientationMatrix!, 0);
          double l2 = OsVec3D.normalizeMatVec(
              _dicomInfo!.originalImageOrientationMatrix!, 4);
          //make sure that the vectors are not too close to the null vector:
          if (l1 > 0.1 && l2 > 0.1) {
            OsVec3D.vectorialProductFromMat(
                _dicomInfo!.originalImageOrientationMatrix!, 0, 4, 8);
            OsVec3D.vectorialProductFromMat(
                _dicomInfo!.originalImageOrientationMatrix!, 8, 0, 4);
            OsVec3D.normalizeMatVec(
                _dicomInfo!.originalImageOrientationMatrix!, 4);
            OsVec3D.normalizeMatVec(
                _dicomInfo!.originalImageOrientationMatrix!, 8);
          } else {
            _dicomInfo!.originalImageOrientationMatrix = null;
          }
        }
      }
    }

    str = _dcm!.getStringElement(DicomTags.tagColumns, null, null);
    if (str.isNotEmpty) _dicomInfo!.width = int.parse(str);
    str = _dcm!.getStringElement(DicomTags.tagRows, null, null);
    if (str.isNotEmpty) _dicomInfo!.height = int.parse(str);
    _dicomInfo!.regionInfo = ImageRegionInfo();
    _dicomInfo!.regionInfo!.dimensions[0] = _dicomInfo!.width;
    _dicomInfo!.regionInfo!.dimensions[1] = _dicomInfo!.height;
    _dicomInfo!.regionInfo!.regions = _dcm!.getRegions();
    _frameCount = 1;
    str = _dcm!.getStringElement(
        DicomTags.tagTransferSyntaxUid, null, null); //transfer syntax
    if (str.isNotEmpty) {
      if (str != "1.2.840.10008.1.2.4.100" &&
          str != "1.2.840.10008.1.2.4.101" &&
          str != "1.2.840.10008.1.2.4.102" &&
          str != "1.2.840.10008.1.2.4.103") {
        str =
            _dcm!.getStringElement('0028:0008', null, null); //number of frames
        if (str.isNotEmpty) {
          _frameCount = int.parse(str);
          if (_frameCount < 1 || _frameCount >= 50000) _frameCount = 1;
        }
      }
    }

    //ACQUISITION DATE:
    String date =
        _dcm!.getStringElement(DicomTags.tagAcquisitionDate, null, null);
    String time =
        _dcm!.getStringElement(DicomTags.tagAcquisitionTime, null, null);
    _dicomInfo!.acquisitionDate = DateUtils.createDateTimeFromDicom(date, time);

    //CONTENT DATE:
    date = _dcm!.getStringElement(DicomTags.tagContentDate, null, null);
    time = _dcm!.getStringElement(DicomTags.tagContentTime, null, null);
    _dicomInfo!.imageDateTime = DateUtils.createDateTimeFromDicom(date, time);
  }
}
