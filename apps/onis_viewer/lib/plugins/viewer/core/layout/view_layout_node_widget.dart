import 'package:onis_viewer/plugins/viewer/core/layout/view_layout_node.dart';

class ViewLayoutNodeWidget {
  WeakReference<ViewLayoutNode>? _layoutNode;

  ViewLayoutNode? get layoutNode => _layoutNode?.target;

  void setLayoutNode(ViewLayoutNode? node) {
    // No need to destroy WeakReference manually in Dart; just overwrite
    if (node != null) {
      _layoutNode = WeakReference<ViewLayoutNode>(node);
    } else {
      _layoutNode = null;
    }
  }
}
