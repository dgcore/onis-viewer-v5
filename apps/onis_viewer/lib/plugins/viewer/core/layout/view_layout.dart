import 'package:onis_viewer/plugins/viewer/core/layout/view_layout_node.dart';

class ViewLayout {
  late ViewLayoutNode rootNode;

  ViewLayout() {
    rootNode = ViewLayoutNode(this);
  }
}
