import 'package:onis_viewer/plugins/database/public/source_controller_interface.dart';

/// Public API exposed by the database plugin
abstract class DatabaseApi {
  ISourceController get sourceController;

  /// Select a source by UID
  //void selectSourceByUid(String uid);

  /// Currently selected source (if any)
  //DatabaseSource? get selectedSource;

  /// Stream emitting selection changes
  //Stream<DatabaseSource?> get onSelectionChanged;

  /// Check if the currently selected source still exists and select alternative if needed
  //void checkAndFixSelection([String? destroyedSourceUid]);

  /// Expand or collapse a source node in the source tree
  /// [uid] - The UID of the source to expand/collapse
  /// [expand] - true to expand, false to collapse
  /// [expandChildren] - true to also expand immediate children
  //void expandSourceNode(String uid,
  //  {bool expand = true, bool expandChildren = false});
}
