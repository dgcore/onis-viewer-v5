import 'package:onis_viewer/plugins/viewer/core/layout/view_layout.dart';
import 'package:onis_viewer/plugins/viewer/public/layout_controller_interface.dart';

class LayoutController extends ILayoutController {
  late ViewLayout _layout;
  LayoutController() {
    _layout = ViewLayout();
  }

  Future<void> initialize() async {}
}
