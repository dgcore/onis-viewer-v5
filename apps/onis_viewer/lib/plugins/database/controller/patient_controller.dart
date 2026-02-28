import 'package:flutter/material.dart';
import 'package:onis_viewer/core/models/database/patient.dart' as database;
import 'package:onis_viewer/core/models/entities/patient.dart' as entities;
import 'package:onis_viewer/core/responses/find_study_response.dart';
import 'package:onis_viewer/plugins/database/public/patient_controller_interface.dart';
import 'package:onis_viewer/plugins/database/ui/retrieve_series.dart';

class PatientController extends IPatientController {
  final List<entities.Patient> _patients = [];

  @override
  entities.Patient? findPatient(database.Patient patient) {
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
    if (notify) notifyListeners();
  }

  @override
  void forceNotification() {
    notifyListeners();
  }

  @override
  Future<void> openPatients(List<database.Patient> patients,
      FindPatientStudyItem? primary, BuildContext context) async {
    if (patients.isEmpty) return;
    // Show retrieve series dialog with patients and primary study
    List<FindPatientStudyItem>? items =
        await RetrieveSeriesDialog.show(context, patients: patients);
    if (items == null) return;
    List<entities.Patient> newPatients = [];
    for (final item in items) {
      //does this patient is already opened?
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
        entities.Study study = entities.Study();
        study.databaseInfo = item.study;
        patient.addStudy(study);
        for (final dbSeries in item.series) {
          entities.Series series = entities.Series();
          series.databaseInfo = dbSeries;
          study.addSeries(series);
        }
      }
      if (doRegister) {
        _patients.add(patient);
        newPatients.add(patient);
      }
    }
    forceNotification();
  }
}
