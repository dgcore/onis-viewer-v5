import 'package:flutter/material.dart';

import '../../core/page_type.dart';
import '../../core/plugin_interface.dart';
import 'page/database_page.dart';

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
  }

  @override
  Future<void> dispose() async {
    // Unregister the page type (includes page creator)
    PageType.unregister(databasePageType.id);
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
}
