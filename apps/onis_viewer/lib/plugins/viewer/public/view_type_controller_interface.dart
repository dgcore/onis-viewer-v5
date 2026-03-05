import 'package:flutter/material.dart';
import 'package:onis_viewer/core/layout/view_type.dart';

abstract class IViewTypeController extends ChangeNotifier {
  bool registerViewType(ViewType viewType);
  bool unregisterViewType(ViewType viewType);
  ViewType? getViewType(String id);
  List<ViewType> getViewTypes();
}
