import 'package:onis_viewer/plugins/viewer/core/layout/view_layout.dart';
import 'package:onis_viewer/plugins/viewer/core/layout/view_layout_node_widget.dart';

class ViewLayoutNode {
  final WeakReference<ViewLayout> _layout;
  WeakReference<ViewLayoutNode>? _parent;
  ViewLayoutNode? _child1;
  ViewLayoutNode? _child2;
  ViewLayoutNodeWidget? _leafWidget;
  final double _ratio = 0.5;
  final bool _active = false;
  final bool _verticalSplit = false;

  ViewLayoutNode(ViewLayout layout)
      : _layout = WeakReference<ViewLayout>(layout);

  bool get isLeaf => _leafWidget != null;
  bool get isActive => _active;
  bool get isVerticalSplit => _verticalSplit;
  double get ratio => _ratio;
  ViewLayoutNodeWidget? get leafWidget => _leafWidget;
  ViewLayout get layout => _layout.target!;
  ViewLayoutNode? get parent => _parent?.target;
}
