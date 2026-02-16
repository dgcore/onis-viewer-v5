import 'package:onis_viewer/plugins/viewer/core/layout/view_layout.dart';
import 'package:onis_viewer/plugins/viewer/core/layout/view_layout_node.dart';
import 'package:onis_viewer/plugins/viewer/public/layout_controller_interface.dart';

class LayoutController extends ILayoutController {
  late ViewLayout _layout;
  LayoutController() {
    _layout = ViewLayout();
  }

  ViewLayout get layout => _layout;
  @override
  ViewLayoutNode get rootNode => _layout.rootNode;

  Future<void> initialize() async {
    rootNode.split(true, 0.5, false);
    rootNode.child1?.split(false, 0.5, false);
    rootNode.child2?.split(false, 0.5, false);
  }
}
