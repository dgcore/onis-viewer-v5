import 'package:flutter/material.dart';

abstract class OsToolbarItem {
  String _id = '';
  String _name = '';
  bool show = true;

  OsToolbarItem(String id, String name) {
    _id = id;
    _name = name;
  }

  String get id => _id;
  String get name => _name;

  Widget get widget;
}

class OsToolbar extends ChangeNotifier {
  String _id = '';
  final List<OsToolbarItem> _items = [];

  OsToolbar(String id) {
    _id = id;
  }

  String get id => _id;
  List<OsToolbarItem> get items => List.unmodifiable(_items);

  void addItem(OsToolbarItem item) {
    _items.add(item);
  }

  void removeItem(OsToolbarItem item) {
    _items.remove(item);
  }
}
