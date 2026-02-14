import 'package:onis_viewer/plugins/viewer/public/layout_controller_interface.dart';

/// Public API exposed by the database plugin
abstract class ViewerApi {
  ILayoutController get layoutController;
}
