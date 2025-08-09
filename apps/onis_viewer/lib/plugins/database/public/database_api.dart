import 'dart:async';

import '../../../core/database_source.dart';

/// Public API exposed by the database plugin
abstract class DatabaseApi {
  /// Select a source by UID
  void selectSourceByUid(String uid);

  /// Currently selected source (if any)
  DatabaseSource? get selectedSource;

  /// Stream emitting selection changes
  Stream<DatabaseSource?> get onSelectionChanged;
}
