import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/core/ov_api_core.dart';
import '../../core/database_source.dart';
import '../../core/page_type.dart';
import '../../core/plugin_interface.dart';
import 'page/database_page.dart';
import 'public/database_api.dart';
import 'ui/database_source_bar.dart';

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

    if (match != null) {
      _selected = match;
    } else {
      // Source not found, try to select an alternative
      debugPrint('Source with UID $uid not found, selecting alternative');
      _selectAlternativeSource();
    }

    _selectionController.add(_selected);
  }

  /// Select an alternative source when the current selection is no longer available
  void _selectAlternativeSource([String? destroyedSourceUid]) {
    final manager = OVApi().sources;
    final allSources = manager.allSources;

    if (allSources.isEmpty) {
      _selected = null;
      return;
    }

    // If we know which source was destroyed, try to find its parent first
    if (destroyedSourceUid != null) {
      // Look for a source that has the destroyed source as a child
      final parentSource = allSources.where((source) {
        return source.subSources
            .any((child) => child.uid == destroyedSourceUid);
      }).firstOrNull;

      if (parentSource != null) {
        _selected = parentSource;
        debugPrint('Selected parent of destroyed source: ${parentSource.name}');
        return;
      }
    }

    // Try to find an active source first
    final activeSource = allSources.where((s) => s.isActive).firstOrNull;
    if (activeSource != null) {
      _selected = activeSource;
      debugPrint('Selected alternative active source: ${activeSource.name}');
      return;
    }

    // If no active sources, select the first available source
    _selected = allSources.first;
    debugPrint('Selected alternative source: ${_selected!.name}');
  }

  /// Check if the currently selected source still exists and select alternative if needed
  @override
  void checkAndFixSelection([String? destroyedSourceUid]) {
    if (_selected == null) {
      _selectAlternativeSource(destroyedSourceUid);
      if (_selected != null) {
        _selectionController.add(_selected);
      }
      return;
    }

    final manager = OVApi().sources;
    final sourceStillExists =
        manager.allSources.any((s) => s.uid == _selected!.uid);

    if (!sourceStillExists) {
      debugPrint(
          'Currently selected source no longer exists, selecting alternative');
      _selectAlternativeSource(destroyedSourceUid);
      _selectionController.add(_selected);
    }
  }

  @override
  DatabaseSource? get selectedSource => _selected;

  @override
  Stream<DatabaseSource?> get onSelectionChanged => _selectionController.stream;

  @override
  void expandSourceNode(String uid,
      {bool expand = true, bool expandChildren = false}) {
    // Direct call to static methods in DatabaseSourceBar
    if (expand) {
      DatabaseSourceBar.expandNode(uid, expandChildren: expandChildren);
    } else {
      DatabaseSourceBar.collapseNode(uid);
    }
  }
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
