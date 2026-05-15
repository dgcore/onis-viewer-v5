import 'package:flutter/material.dart';
import 'package:onis_viewer/core/models/database/patient.dart' as database;
import 'package:onis_viewer/core/models/entities/patient.dart' as entities;
import 'package:onis_viewer/core/responses/find_study_response.dart';

/// Cross-window opened-patient session state (see `OpenedPatientsService`).
abstract class IPatientController extends ChangeNotifier {
  List<entities.Patient> get patients;
  entities.Patient? findPatient(database.Patient patient);
  void registerPatient(entities.Patient patient, bool notify);
  Future<void> openPatients(List<database.Patient> patients,
      FindPatientStudyItem? primary, BuildContext context);
  entities.Image? findImageByGuids(String patientGuid, String studyGuid,
      String seriesGuid, String imageGuid);
  entities.Series? findSeriesByGuids(
      String patientGuid, String studyGuid, String seriesGuid);
  void forceNotification();
}
