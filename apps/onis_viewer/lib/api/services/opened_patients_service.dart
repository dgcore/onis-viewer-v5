import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onis_viewer/api/core/ov_api_core.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:onis_viewer/api/services/message_codes.dart';
import 'package:onis_viewer/api/services/patient_controller_interface.dart';
import 'package:onis_viewer/core/models/database/patient.dart' as db_patient;
import 'package:onis_viewer/core/models/entities/patient.dart' as entities;
import 'package:onis_viewer/core/responses/find_study_response.dart';
import 'package:onis_viewer/plugins/database/ui/retrieve_series.dart';
import 'package:uuid_v4/uuid_v4.dart';

class OpenedPatientsService extends IPatientController {
  final List<entities.Patient> _patients = [];
  int? _messageSubscriptionId;
  int _version = 0;

  OpenedPatientsService() {
    _messageSubscriptionId =
        OVApi().messages.subscribe(_handleCrossWindowMessage);
    _requestSnapshotFromPeers();
  }

  @override
  void dispose() {
    final subscriptionId = _messageSubscriptionId;
    if (subscriptionId != null) {
      OVApi().messages.unsubscribe(subscriptionId);
      _messageSubscriptionId = null;
    }
    super.dispose();
  }

  @override
  List<entities.Patient> get patients => List.unmodifiable(_patients);

  @override
  entities.Patient? findPatient(db_patient.Patient patient) {
    for (final item in _patients) {
      if (item.databaseInfo == null) continue;
      if (item.databaseInfo!.sourceUid == patient.sourceUid &&
          item.databaseInfo!.id == patient.id &&
          item.databaseInfo!.pid == patient.pid) {
        return item;
      }
    }
    return null;
  }

  @override
  void registerPatient(entities.Patient patient, bool notify) {
    _patients.add(patient);
    if (notify) {
      forceNotification();
    }
  }

  @override
  entities.Series? findSeriesByGuids(
      String patientGuid, String studyGuid, String seriesGuid) {
    final patient = patients
        .where((patient) => patient.guid == patientGuid)
        .cast<entities.Patient?>()
        .firstWhere((p) => p != null, orElse: () => null);
    if (patient == null) return null;
    final study = patient.studies
        .where((study) => study.guid == studyGuid)
        .cast<entities.Study?>()
        .firstWhere((s) => s != null, orElse: () => null);
    if (study == null) return null;
    final series = study.series
        .where((series) => series.guid == seriesGuid)
        .cast<entities.Series?>()
        .firstWhere((s) => s != null, orElse: () => null);
    return series;
  }

  @override
  entities.Image? findImageByGuids(String patientGuid, String studyGuid,
      String seriesGuid, String imageGuid) {
    final series = findSeriesByGuids(patientGuid, studyGuid, seriesGuid);
    if (series == null) return null;
    final image = series.images
        .where((image) => image.guid == imageGuid)
        .cast<entities.Image?>()
        .firstWhere((i) => i != null, orElse: () => null);
    return image;
  }

  @override
  void forceNotification() {
    notifyListeners();
  }

  @override
  Future<void> openPatients(List<db_patient.Patient> patients,
      FindPatientStudyItem? primary, BuildContext context) async {
    if (patients.isEmpty) return;
    final items = await RetrieveSeriesDialog.show(context, patients: patients);
    if (items == null) return;
    final newPatients = <entities.Patient>[];
    for (final item in items) {
      bool doRegister = false;
      bool addStudies = false;
      entities.Patient? patient = findPatient(item.patient);
      if (patient != null) {
        if (newPatients.contains(patient)) {
          addStudies = true;
        }
      } else {
        patient = entities.Patient();
        patient.databaseInfo = item.patient;
        doRegister = true;
        addStudies = true;
      }
      if (addStudies) {
        final study = entities.Study();
        study.databaseInfo = item.study;
        patient.addStudy(study);
        for (final dbSeries in item.series) {
          final series = entities.Series();
          series.databaseInfo = dbSeries;
          study.addSeries(series);
        }
      }
      if (doRegister) {
        _patients.add(patient);
        newPatients.add(patient);
      }
    }
    _publishStateUpdate();
  }

  void _publishStateUpdate() {
    _version++;
    forceNotification();
    _broadcastSnapshot();
  }

  void _broadcastSnapshot() {
    final payload = <String, dynamic>{
      'originEngineId': OVApi().flutterEngineInstanceId,
      'version': _version,
      'patients': _patients.map((p) => p.toJson()).toList(growable: false),
    };
    OVApi().messages.sendMessage(OSMSG.openedPatientsSnapshot, payload);
  }

  void _handleCrossWindowMessage(int id, dynamic data) {
    if (id == OSMSG.openedPatientsSyncRequest) {
      final origin =
          data is Map ? (data['originEngineId'] as num?)?.toInt() : null;
      if (origin != null && origin != OVApi().flutterEngineInstanceId) {
        _broadcastSnapshot();
      }
      return;
    }
    if (id != OSMSG.openedPatientsSnapshot) {
      return;
    }
    if (data is! Map) {
      return;
    }
    final origin = (data['originEngineId'] as num?)?.toInt();
    if (origin == OVApi().flutterEngineInstanceId) {
      return;
    }
    final incomingVersion = (data['version'] as num?)?.toInt() ?? 0;
    if (incomingVersion < _version) {
      return;
    }
    final rawPatients = data['patients'];
    if (rawPatients is! List) {
      return;
    }
    final rebuilt = <entities.Patient>[];
    for (final rawPatient in rawPatients) {
      if (rawPatient is! Map) continue;
      rebuilt.add(entities.Patient.fromJson(
          true, Map<String, dynamic>.from(rawPatient)));
    }
    _patients
      ..clear()
      ..addAll(rebuilt);
    _version = incomingVersion;
    forceNotification();
  }

  void _requestSnapshotFromPeers() {
    final payload = <String, dynamic>{
      'originEngineId': OVApi().flutterEngineInstanceId,
    };
    OVApi().messages.sendMessage(OSMSG.openedPatientsSyncRequest, payload);
  }

  @override
  void notifySeriesStatusChanged(entities.Series series) {}

  @override
  Future<void> notifyInitialSeriesDownloadInfo(
      entities.Series series, int imageCount, String properties) async {
    List<String> guids = [];
    for (int i = 0; i < imageCount; i++) {
      guids.add(UUIDv4().toString());
    }
    final payload = <String, dynamic>{
      'patient': series.study?.patient?.guid ?? '',
      'study': series.study?.guid ?? '',
      'series': series.guid,
      'images': guids,
    };
    await OVApi()
        .messages
        .sendMessage(OSMSG.syncInitSeriesDownloadInfo, payload);
  }

  @override
  Future<void> notifyImageDownloadUpdate(
    entities.Image image,
    int reason,
    int dicomFileId, {
    String? loadPath,
  }) async {
    final displayOwnsRelease =
        !kIsWeb && (await DesktopMultiWindow.getAllSubWindowIds()).isNotEmpty;
    final payload = <String, dynamic>{
      'patient': image.series?.study?.patient?.guid ?? '',
      'study': image.series?.study?.guid ?? '',
      'series': image.series?.guid ?? '',
      'image': image.guid,
      'reason': reason,
      'dicomFileId': dicomFileId,
      'displayOwnsRelease': displayOwnsRelease,
      if (loadPath != null && loadPath.isNotEmpty) 'loadPath': loadPath,
    };
    await OVApi().messages.sendMessage(OSMSG.syncImageDownloadUpdate, payload);
  }
}
