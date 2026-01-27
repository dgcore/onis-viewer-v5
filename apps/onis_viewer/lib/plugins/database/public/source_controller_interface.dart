import 'package:flutter/material.dart';
import 'package:onis_viewer/core/database_source.dart';

/// Interface for SourceController functionality
abstract class ISourceController extends ChangeNotifier {
  DatabaseSourceManager get sources;
  DatabaseSource? get selectedSource;

  int get totalStudyCount;

  void selectSourceByUid(String sourceUid);
  void expandSourceNode(String sourceUid,
      {bool expand = true, bool expandChildren = false});
  bool canSearch(String sourceUid);
  bool canImport(String sourceUid);
  bool canExport(String sourceUid);
  bool canOpen(String sourceUid);
  bool canTransfer(String sourceUid);
}
