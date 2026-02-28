import 'package:flutter/material.dart';
import 'package:onis_viewer/core/models/database/patient.dart' as database;
import 'package:onis_viewer/core/models/entities/patient.dart' as entities;
import 'package:onis_viewer/core/responses/find_study_response.dart';

/// Interface for IPatientController functionality
abstract class IPatientController extends ChangeNotifier {
  List<entities.Patient> get patients;
  entities.Patient? findPatient(database.Patient patient);
  void registerPatient(entities.Patient patient, bool notify);
  Future<void> openPatients(List<database.Patient> patients,
      FindPatientStudyItem? primary, BuildContext context);
  void forceNotification();
}
