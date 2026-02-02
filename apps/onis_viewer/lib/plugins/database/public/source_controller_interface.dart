import 'package:flutter/material.dart';
import 'package:onis_viewer/core/database_source.dart';
import 'package:onis_viewer/core/models/database/patient.dart' as database;
import 'package:onis_viewer/core/models/database/study.dart' as database;
import 'package:onis_viewer/core/responses/find_study_response.dart';

/// Interface for SourceController functionality
abstract class ISourceController extends ChangeNotifier {
  DatabaseSourceManager get sources;
  DatabaseSource? get selectedSource;

  int get totalStudyCount;

  void notifyUpdate();
  void selectSourceByUid(String sourceUid);
  void expandSourceNode(String sourceUid,
      {bool expand = true, bool expandChildren = false});
  bool canSearch(String sourceUid);
  bool canImport(String sourceUid);
  bool canExport(String sourceUid);
  bool canOpen(String sourceUid);
  bool canTransfer(String sourceUid);
  Future<FindPatientStudyResponse> findStudies(String sourceUid);
  void setStudies(FindPatientStudyResponse response);
  void clearStudies(String sourceUid);
  List<({database.Patient patient, database.Study study})> getStudiesForSource(
      String sourceUid);
  List<({database.Patient patient, database.Study study})>
      getSelectedStudiesForSource(String sourceUid);
}
