import 'package:flutter/material.dart';
import 'package:onis_viewer/core/database_source.dart';

/// Interface for SourceController functionality
abstract class ISourceController extends ChangeNotifier {
  DatabaseSourceManager get sources;
  DatabaseSource? get selectedSource;
  //DatabaseSourceLoginState? getLoginState(String sourceUid);
  int get totalStudyCount;

  void selectSourceByUid(String uid);
}
