import 'package:flutter/material.dart';
import 'package:onis_viewer/core/database_source.dart';
import 'package:onis_viewer/core/models/database/filter.dart';
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
  Future<Map<String, dynamic>?> importDicomFile(
      String sourceUid, String filePath);
  Future<FindPatientStudyResponse> findStudies(String sourceUid,
      {DBFilters? filters, bool withSeries = false});
  void setStudies(FindPatientStudyResponse response);
  void clearStudies(String sourceUid);
  List<FindPatientStudyItem> getStudiesForSource(String sourceUid);
  List<FindPatientStudyItem> getSelectedStudiesForSource(String sourceUid);
  void openSelectedStudies(String sourceUid, BuildContext context);
  ({double horizontal, double vertical}) getScrollPositionsForSource(
      String sourceUid);
  void saveScrollPositionsForSource(
      String sourceUid, double horizontalPosition, double verticalPosition);
  List<({String sourceUid, int status})> getSourceStatuses(String sourceUid);
}
