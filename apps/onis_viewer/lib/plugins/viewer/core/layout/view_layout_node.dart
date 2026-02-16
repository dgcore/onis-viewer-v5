import 'package:onis_viewer/plugins/viewer/core/layout/view_layout.dart';
import 'package:onis_viewer/plugins/viewer/core/layout/view_layout_node_widget.dart';

class ViewLayoutNode {
  final WeakReference<ViewLayout> _layout;
  WeakReference<ViewLayoutNode>? _parent;
  ViewLayoutNode? _child1;
  ViewLayoutNode? _child2;
  ViewLayoutNodeWidget? _leafWidget;
  double _ratio = 0.5;
  final bool _active = false;
  bool _verticalSplit = false;

  ViewLayoutNode(ViewLayout layout, ViewLayoutNodeWidget? dial)
      : _layout = WeakReference<ViewLayout>(layout) {
    if (dial != null) {
      _leafWidget = dial;
      dial.setLayoutNode(this);
    } else {
      _leafWidget = ViewLayoutNodeWidget();
    }
  }

  bool get isLeaf => _leafWidget != null;
  bool get isActive => _active;
  bool get isVerticalSplit => _verticalSplit;
  double get ratio => _ratio;
  ViewLayoutNodeWidget? get leafWidget => _leafWidget;
  ViewLayout? get layout => _layout.target;
  ViewLayoutNode? get parent => _parent?.target;
  ViewLayoutNode? get child1 => _child1;
  ViewLayoutNode? get child2 => _child2;

  void split(bool vertical, double ratio, bool notify) {
    if (_leafWidget == null && _verticalSplit == vertical) return;
    if (layout == null) return;
    _verticalSplit = vertical;
    _ratio = ratio;
    bool done = false;
    if (_leafWidget != null) {
      //layout.clearTilingValues();
      bool wasActive = _active;
      //if (_active) layout.setActiveNode(null, true);
      _verticalSplit = vertical;
      _child1 = ViewLayoutNode(layout!, _leafWidget);
      _child2 = ViewLayoutNode(layout!, null);
      _child1!._parent = WeakReference<ViewLayoutNode>(this);
      _child2!._parent = WeakReference<ViewLayoutNode>(this);
      _leafWidget = null;
      //if (wasActive) layout.setActiveNode(_child1, true);*/
      done = true;
    }
    /*if (refresh) {
            this.setRect(this._rect);
            if (_child2 && _child2.getLeafWindow() != null) {
                let tmp:OsViewLayoutNodeWnd|null = _child2.getLeafWindow();
                if (tmp) tmp.show(true);
            }
        }*/
  }
}
