import 'package:flutter/material.dart';
import 'package:onis_viewer/api/core/ov_api_core.dart';
import 'package:onis_viewer/core/layout/view_layout_node.dart';
import 'package:onis_viewer/core/layout/view_layout_node_wnd.dart';
import 'package:onis_viewer/core/layout/view_type.dart';

class ViewLayout extends ChangeNotifier {
  late ViewLayoutNode _rootNode;
  WeakReference<ViewLayoutNode>? _wzoomedNode;
  WeakReference<ViewLayoutNode>? _wactiveNode;
  bool _supportAllViewTypes = true;
  final List<ViewType> _viewTypes = [];
  final List<ViewLayoutNodeWnd> _stockOfLayoutWindows = [];
  int _defTileRows = 0;
  int _defTileCols = 0;

  ViewLayout() {
    _rootNode = ViewLayoutNode(this, null);
  }

  void notifyLayoutChanged() {
    super.notifyListeners();
  }

  //----------------------------------------------------------
  // Root node
  //----------------------------------------------------------

  ViewLayoutNode get rootNode => _rootNode;
  set rootNode(ViewLayoutNode node) {
    _rootNode = node;
  }

  //----------------------------------------------------------
  // Activation
  //----------------------------------------------------------

  ViewLayoutNode? get activeNode {
    return _wactiveNode?.target;
  }

  set activeNode(ViewLayoutNode? node) {
    ViewLayoutNode? previousActiveNode = activeNode;
    if (previousActiveNode == node) {
      if (node != null) node.activate(true);
      return;
    }
    _wactiveNode = node != null ? WeakReference<ViewLayoutNode>(node) : null;
    previousActiveNode?.activate(false);
    node?.activate(true);
  }

  void activateFirstNode() {
    List<ViewLayoutNode> list = [];
    _rootNode.getAllNodes(list);
    for (ViewLayoutNode node in list) {
      if (node.isLeaf) {
        activeNode = node;
        break;
      }
    }
  }

  //----------------------------------------------------------
  // Zoom
  //----------------------------------------------------------

  bool canZoom() {
    if (_rootNode.isLeaf) return false;
    if (_wzoomedNode != null) {
      if (_wzoomedNode!.target == null) {
        _wzoomedNode = null;
      }
    }
    if (_wzoomedNode != null) return false;
    return true;
  }

  ViewLayoutNode? get zoomedNode {
    return _wzoomedNode?.target;
  }

  void zoom(ViewLayoutNode? node) {
    ViewLayoutNode? currentZoomedNode = zoomedNode;
    if (node == null && currentZoomedNode == null) return;
    if (currentZoomedNode != null && currentZoomedNode == node) return;
    if (node == _rootNode) return;
    _wzoomedNode = node != null ? WeakReference<ViewLayoutNode>(node) : null;
    bool show = node == null;
    List<ViewLayoutNodeWnd> list = [];
    getAllWindows(list);
    for (ViewLayoutNodeWnd wnd in list) {
      wnd.show = show;
    }
    if (node != null) {
      ViewLayoutNodeWnd? nf = node.leafWidget;
      if (nf != null) nf.show = true;
      activeNode = node;
    }
  }

  //----------------------------------------------------------
  // Tiling
  //----------------------------------------------------------

  void clearTilingValues() {
    _defTileCols = 0;
    _defTileRows = 0;
  }

  bool getTiling(List<int> rowCol) {
    if (_rootNode.isLeaf) {
      rowCol[0] = 1;
      rowCol[1] = 1;
      return true;
    }
    if (_defTileRows == 0 || _defTileCols == 0) return false;
    rowCol[0] = _defTileRows;
    rowCol[1] = _defTileCols;
    return true;
  }

  void setTiling(int rows, int columns) {
    if (rows < 1 || rows > 10) return;
    if (columns < 1 || columns > 10) return;
    if (rows == _defTileRows && columns == _defTileCols) {
      if (zoomedNode != null) zoom(null);
      return;
    }
    _defTileRows = rows;
    _defTileCols = columns;
    if (zoomedNode != null) zoom(null);
    List<ViewLayoutNodeWnd> previousWnds = [];
    getAllWindows(previousWnds);

    //Detach all the leaf window, hide and store them:
    List<ViewLayoutNode> nodes = [];
    _rootNode.getAllNodes(nodes);
    for (ViewLayoutNode node in nodes) {
      if (!node.isLeaf) continue;
      if (node.isActive) {
        node.activate(false);
      }
      ViewLayoutNodeWnd? dial = node.leafWidget;
      if (dial != null) {
        _stockOfLayoutWindows.add(dial);
        dial.show = false;
        dial.layoutNode = null;
        node.leafWidget = null;
      }
    }

    //Reset the layout:
    _wactiveNode = null;

    //Reconstruct the layout:
    if (_stockOfLayoutWindows.isNotEmpty) {
      _rootNode = ViewLayoutNode(this, _getCandidate());
    } else {
      _rootNode = ViewLayoutNode(this, null);
    }

    ViewLayoutNode? currentNode = _rootNode;
    for (int j = 1; j < rows; j++) {
      ViewLayoutNodeWnd? candidate = _getCandidate();
      if (currentNode != null) {
        currentNode.init(
            false, 1.0 / (rows - j + 1), currentNode, candidate, this);
        currentNode = currentNode.child2;
      }
    }

    List<ViewLayoutNodeWnd> listWnds = [];
    _rootNode.getAllWindows(listWnds);
    for (ViewLayoutNodeWnd wnd in listWnds) {
      currentNode = wnd.layoutNode;
      for (int j = 1; j < columns; j++) {
        ViewLayoutNodeWnd? candidate = _getCandidate();
        if (currentNode != null) {
          currentNode.init(
              true, 1.0 / (columns - j + 1), currentNode, candidate, this);
          currentNode = currentNode.child2;
        }
      }
    }

    //reset the view types:
    final defaultViewType = OVApi().viewTypes.getViewType("VIEWTYPE_2D");
    if (defaultViewType != null) {
      listWnds.clear();
      _rootNode.getAllWindows(listWnds);
      for (ViewLayoutNodeWnd wnd in listWnds) {
        if (!previousWnds.contains(wnd)) {
          wnd.setCurrentViewType(defaultViewType, 0);
        }
      }
    }
    activateFirstNode();
    _stockOfLayoutWindows.clear();

    //make sure all windows are visible:
    List<ViewLayoutNodeWnd> list = [];
    getAllWindows(list);
    for (ViewLayoutNodeWnd wnd in list) {
      wnd.show = true;
    }
  }

  ViewLayoutNodeWnd? _getCandidate() {
    for (int i = 0; i < _stockOfLayoutWindows.length; i++) {
      if (_stockOfLayoutWindows[i].haveContent) {
        ViewLayoutNodeWnd ret = _stockOfLayoutWindows[i];
        _stockOfLayoutWindows.removeAt(i);
        return ret;
      }
    }
    if (_stockOfLayoutWindows.isEmpty) {
      return null;
    } else {
      ViewLayoutNodeWnd ret = _stockOfLayoutWindows[0];
      _stockOfLayoutWindows.removeAt(0);
      return ret;
    }
  }

  void getAllWindows(List<ViewLayoutNodeWnd> list) {
    _rootNode.getAllWindows(list);
  }

  //----------------------------------------------------------
  //view types
  //----------------------------------------------------------

  set supportAllViewTypes(support) {
    _supportAllViewTypes = support;
    if (_supportAllViewTypes) _viewTypes.clear();
  }

  bool addViewType(ViewType type) {
    if (_supportAllViewTypes) return false;
    if (_viewTypes.contains(type)) return true;
    _viewTypes.add(type);
    return true;
  }

  bool removeViewType(ViewType type) {
    if (_supportAllViewTypes) return false;
    int pos = _viewTypes.indexOf(type);
    if (pos >= 0) _viewTypes.removeAt(pos);
    return true;
  }

  get listOfViewTypes {
    if (_supportAllViewTypes) {
      return OVApi().viewTypes.getViewTypes();
    }
    return _viewTypes;
  }
}
