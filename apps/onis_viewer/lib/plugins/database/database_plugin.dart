import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/core/ov_api_core.dart';
import '../../core/database_source.dart';
import '../../core/page_type.dart';
import '../../core/plugin_interface.dart';
import 'page/database_page.dart';
import 'public/database_api.dart';

class _DatabaseApiImpl implements DatabaseApi {
  final _selectionController = StreamController<DatabaseSource?>.broadcast();
  DatabaseSource? _selected;

  @override
  void selectSourceByUid(String uid) {
    final manager = OVApi().sources;
    final match = manager.allSources
        .where((s) => s.uid == uid)
        .cast<DatabaseSource?>()
        .firstWhere(
          (s) => s != null,
          orElse: () => null,
        );
    _selected = match;
    _selectionController.add(_selected);
  }

  @override
  DatabaseSource? get selectedSource => _selected;

  @override
  Stream<DatabaseSource?> get onSelectionChanged => _selectionController.stream;
}

/// Database page type constant
const PageType databasePageType = PageType(
  id: 'database',
  name: 'Database',
  description: 'Manage and browse medical image databases',
  icon: Icons.storage,
  color: Colors.blue,
  pageCreator: _createDatabasePage,
);

/// Create database page widget
Widget _createDatabasePage(PageType pageType) {
  return const DatabasePage();
}

/// Built-in database plugin
class DatabasePlugin implements OnisViewerPlugin {
  _DatabaseApiImpl? _api;

  @override
  String get id => 'onis_database_plugin';

  @override
  String get name => 'Database Plugin';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Provides database management functionality';

  @override
  String get author => 'ONIS Team';

  @override
  IconData? get icon => Icons.storage;

  @override
  Color? get color => Colors.blue;

  @override
  Future<void> initialize() async {
    // Register the page type (includes page creator)
    PageType.register(databasePageType);
    // Create public API implementation
    _api = _DatabaseApiImpl();
  }

  @override
  Future<void> dispose() async {
    // Unregister the page type (includes page creator)
    PageType.unregister(databasePageType.id);
    _api = null;
  }

  @override
  bool get isValid => true;

  @override
  Map<String, dynamic> get metadata => {
        'id': id,
        'name': name,
        'version': version,
        'description': description,
        'author': author,
      };

  @override
  Object? get publicApi => _api;
}
