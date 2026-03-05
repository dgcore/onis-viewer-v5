import 'package:onis_viewer/api/core/ov_api_core.dart';
import 'package:onis_viewer/core/layout/view_layout.dart';
import 'package:onis_viewer/core/layout/view_layout_node.dart';
import 'package:onis_viewer/core/layout/view_type.dart';
import 'package:onis_viewer/core/layout/view_wnd.dart';

class ViewLayoutNodeWnd {
  WeakReference<ViewLayoutNode>? _layoutNode;
  final List<ViewWnd> _viewTypeWindows = [];
  ViewWnd? _currentViewTypeWindow;
  bool _show = true;

  ViewLayoutNodeWnd(ViewLayoutNode node) {
    _layoutNode = WeakReference<ViewLayoutNode>(node);
    ViewLayout? layout = node.layout;
    if (layout != null) {
      final defaultViewType = OVApi().viewTypes.getViewType("VIEWTYPE_2D");
      if (defaultViewType != null) {
        setCurrentViewType(defaultViewType, 0);
      }
    }
  }

  // getters:
  ViewLayoutNode? get layoutNode => _layoutNode?.target;
  ViewWnd? get currentViewWindow => _currentViewTypeWindow;
  List<ViewWnd> get viewWindows => _viewTypeWindows;
  bool get show => _show;
  bool get haveContent => false;

  // setters:
  set layoutNode(ViewLayoutNode? node) {
    if (node != null) {
      _layoutNode = WeakReference<ViewLayoutNode>(node);
    } else {
      _layoutNode = null;
    }
  }

  set show(bool value) {
    _show = value;
  }

  void setCurrentViewType(ViewType type, int index) {
    _currentViewTypeWindow = null;
    bool found = false;
    for (int i = 0; i < _viewTypeWindows.length; i++) {
      if (_viewTypeWindows[i].type == type) {
        found = true;
        _currentViewTypeWindow = _viewTypeWindows[i];
        _viewTypeWindows[i].show = true;
        //_viewTypeWindows[i].configureForIndex(index);
      }
    }
    if (!found && layoutNode != null) {
      ViewLayout? vl = layoutNode!.layout;
      if (vl != null) {
        List<ViewType> supportList = vl.listOfViewTypes;
        if (supportList.contains(type)) {
          ViewWnd? dial = type.createView(this, index);
          if (dial != null) {
            _viewTypeWindows.add(dial);
            _currentViewTypeWindow = dial;
            dial.show = true;
          }
        }
      }
    }
  }

  (ViewType?, int) getCurrentViewType() {
    if (_currentViewTypeWindow != null) {
      return (_currentViewTypeWindow!.type, _currentViewTypeWindow!.index);
    }
    return (null, -1);
  }
}
