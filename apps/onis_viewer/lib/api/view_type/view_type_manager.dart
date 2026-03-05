import 'package:flutter/material.dart';
import 'package:onis_viewer/api/view_type/2D/view_type_2d.dart';
import 'package:onis_viewer/core/layout/view_type.dart';

class ViewTypeManager extends ChangeNotifier {
  final List<ViewType> _viewTypes = [];

  ViewTypeManager();

  void initialize() {
    ViewType2D viewType2D = ViewType2D("2D", "VIEWTYPE_2D");
    registerViewType(viewType2D);
  }

  bool registerViewType(ViewType viewType) {
    if (getViewType(viewType.id) != null) {
      return false;
    }
    _viewTypes.add(viewType);
    notifyListeners();
    return true;
  }

  bool unregisterViewType(ViewType viewType) {
    if (getViewType(viewType.id) != null) {
      _viewTypes.remove(viewType);
      notifyListeners();
      return true;
    }
    return false;
  }

  ViewType? getViewType(String id) {
    for (ViewType viewType in _viewTypes) {
      if (viewType.id == id) {
        return viewType;
      }
    }
    return null;
  }

  List<ViewType> getViewTypes() {
    return List.unmodifiable(_viewTypes);
  }
}
