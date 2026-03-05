import 'package:onis_viewer/core/layout/view_layout.dart';
import 'package:onis_viewer/core/layout/view_layout_node_wnd.dart';
import 'package:onis_viewer/core/layout/view_wnd.dart';

class ViewLayoutNode {
  final WeakReference<ViewLayout> _layout;
  WeakReference<ViewLayoutNode>? _parent;
  ViewLayoutNode? _child1;
  ViewLayoutNode? _child2;
  ViewLayoutNodeWnd? _leafWnd;
  double _ratio = 0.5;
  bool _active = false;
  bool _verticalSplit = false;

  ViewLayoutNode(ViewLayout layout, ViewLayoutNodeWnd? dial)
      : _layout = WeakReference<ViewLayout>(layout) {
    if (dial != null) {
      _leafWnd = dial;
      dial.layoutNode = this;
    } else {
      _leafWnd = ViewLayoutNodeWnd(this);
    }
  }

  // getters:
  bool get isLeaf => _leafWnd != null;
  bool get isActive => _active;
  bool get isVerticalSplit => _verticalSplit;
  double get ratio => _ratio;
  ViewLayoutNodeWnd? get leafWidget => _leafWnd;
  ViewLayout? get layout => _layout.target;
  ViewLayoutNode? get parent => _parent?.target;
  ViewLayoutNode? get child1 => _child1;
  ViewLayoutNode? get child2 => _child2;

  // setters:
  set leafWidget(ViewLayoutNodeWnd? value) {
    _leafWnd = value;
  }

  //----------------------------------------------------------
  // Init
  //----------------------------------------------------------

  void init(bool vertical, double ratio, ViewLayoutNode node,
      ViewLayoutNodeWnd? dial, ViewLayout layout) {
    _ratio = ratio;
    _verticalSplit = vertical;
    _child1 = ViewLayoutNode(layout, _leafWnd);
    _child2 = ViewLayoutNode(layout, dial);
    _child1!._parent = WeakReference<ViewLayoutNode>(this);
    _child2!._parent = WeakReference<ViewLayoutNode>(this);
    _leafWnd = null;
  }

  //----------------------------------------------------------
  // Windows
  //----------------------------------------------------------

  void getAllWindows(List<ViewLayoutNodeWnd> list) {
    if (_leafWnd != null) {
      list.add(_leafWnd!);
    } else {
      _child1?.getAllWindows(list);
      _child2?.getAllWindows(list);
    }
  }

  //----------------------------------------------------------
  // Nodes
  //----------------------------------------------------------

  void getAllNodes(List<ViewLayoutNode> list) {
    list.add(this);
    _child1?.getAllNodes(list);
    _child2?.getAllNodes(list);
  }

  void split(bool vertical, double ratio, bool notify) {
    if (_leafWnd == null && _verticalSplit == vertical) return;
    if (layout == null) return;
    _verticalSplit = vertical;
    _ratio = ratio;
    bool done = false;
    if (_leafWnd != null) {
      layout!.clearTilingValues();
      bool wasActive = _active;
      if (_active) layout!.activeNode = null;
      _verticalSplit = vertical;
      _child1 = ViewLayoutNode(layout!, _leafWnd);
      _child2 = ViewLayoutNode(layout!, null);
      _child1!._parent = WeakReference<ViewLayoutNode>(this);
      _child2!._parent = WeakReference<ViewLayoutNode>(this);
      _leafWnd = null;
      if (wasActive) layout!.activeNode = _child1;
      done = true;
    }

    //this.setRect(this._rect);
    if (_child2 != null && _child2!.leafWidget != null) {
      _child2!.leafWidget?.show = true;
    }

    if (done) {
      /*let set:OsDbAnnotationSet|null = null;
            let value:boolean = layout.shouldDisplayDicomAnnotations(null);
            layout.setShouldDisplayDicomAnnotations(value, set, false);
            value = layout.shouldDisplayGraphicAnnotations();
            layout.setShouldDisplayGraphicAnnotations(value, false);
            value = layout.shouldDisplayRuler();
            layout.setShouldDisplayRuler(value, false);
            value = layout.shouldDisplayDicomOverlays();
            layout.setShouldDisplayDicomOverlays(value, false);
            if (layout.viewer) layout.viewer.sendMessage(MSG.VIEWLAYOUT_SPLIT, layout);*/
    }
  }

  void close(bool refresh) {
    if (layout == null) return;
    layout!.clearTilingValues();
    if (layout!.zoomedNode != null) layout!.zoom(null);
    bool wasActive = false;
    ViewLayoutNode? activeNode = layout!.activeNode;
    if (activeNode != null) {
      if (activeNode == this) {
        wasActive = true;
        layout!.activeNode = null;
      } else {
        List<ViewLayoutNode> list = [];
        getAllNodes(list);
        if (list.contains(this)) {
          layout!.activeNode = null;
          wasActive = true;
        }
      }
    }

    ViewLayoutNode? parent2 = parent;
    ViewLayoutNode? parent1 = parent2?.parent;
    ViewLayoutNode? nodeToReattach;
    if (parent2 != null && parent2._child1 == this) {
      nodeToReattach = parent2._child2;
      if (nodeToReattach != null) {
        nodeToReattach._parent = null;
      }
      if (parent2._child2 != null) {
        parent2._child2 = null;
      }
    } else {
      nodeToReattach = parent2?._child1;
      if (nodeToReattach != null) {
        nodeToReattach._parent = null;
      }
      if (parent2 != null && parent2._child1 != null) {
        parent2._child1 = null;
      }
    }
    if (parent1 != null) {
      if (parent1._child1 == parent2) {
        if (parent2 != null) {
          parent2._parent = null;
        }
        parent1._child1 = nodeToReattach;
        if (nodeToReattach != null) {
          nodeToReattach._parent = WeakReference<ViewLayoutNode>(parent1);
        }
      } else {
        if (parent2 != null) {
          parent2._parent = null;
        }
        parent1._child2 = nodeToReattach;
        if (nodeToReattach != null) {
          nodeToReattach._parent = WeakReference<ViewLayoutNode>(parent1);
        }
      }
    } else {
      if (nodeToReattach != null) {
        layout!.rootNode = nodeToReattach;
      }
    }
    if (wasActive) layout!.activateFirstNode();
  }

  void activate(bool activate) {
    if (_active == activate) {
      if (_active) {
        if (_leafWnd != null) {
          ViewWnd? dial = _leafWnd!.currentViewWindow;
          if (dial != null) dial.makeFirstResponder();
        }
      }
      return;
    }
    _active = activate;
    if (!activate) {
      if (_leafWnd != null) {
        ViewWnd? dial = _leafWnd!.currentViewWindow;
        if (dial != null) {
          /*let list:OsContainerWnd[] = [];
          dial.getListOfContainerWindows(list);
          list.forEach(container=>container.unselectAll(true, true, null, null, null));*/
        }
      }
    } else {
      if (_leafWnd != null) {
        ViewWnd? dial = _leafWnd!.currentViewWindow;
        if (dial != null) dial.makeFirstResponder();
      }
    }
  }
}
