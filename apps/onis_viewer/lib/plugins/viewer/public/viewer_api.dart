import 'package:onis_viewer/core/layout/view_layout.dart';
import 'package:onis_viewer/core/toolbar/toolbar_item.dart';

/// Public API exposed by the database plugin
abstract class ViewerApi {
  ViewLayout get layout;
  OsToolbar get toolbar;
}
