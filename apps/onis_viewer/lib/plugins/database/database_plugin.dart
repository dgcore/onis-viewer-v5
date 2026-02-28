import 'dart:async';

import 'package:flutter/material.dart';
import 'package:onis_viewer/plugins/database/controller/patient_controller.dart';
import 'package:onis_viewer/plugins/database/controller/source_controller.dart';
import 'package:onis_viewer/plugins/database/public/patient_controller_interface.dart';
import 'package:onis_viewer/plugins/database/public/source_controller_interface.dart';

//import '../../api/core/ov_api_core.dart';
//import '../../core/database_source.dart';
import '../../core/page_type.dart';
import '../../core/plugin_interface.dart';
import 'page/database_page.dart';
import 'public/database_api.dart';
//import 'ui/database_source_bar.dart';

/*class _DatabaseApiImpl implements DatabaseApi {
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
    /*final manager = OVApi().sources;
    final allSources = manager.allSources;

    if (allSources.isEmpty) {
      _selected = null;
      return;
    }

    // If we know which source was destroyed, try to find its parent first
    if (destroyedSourceUid != null) {
      // First, try to find a source with this exact UID (in case it's a parent site UID)
      final exactMatch = allSources
          .where((source) => source.uid == destroyedSourceUid)
          .firstOrNull;
      if (exactMatch != null) {
        _selected = exactMatch;
        debugPrint(
            'Selected exact match for destroyed source: ${exactMatch.name}');
        return;
      }

      // If no exact match, look for a source that has the destroyed source as a child
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
    debugPrint('Selected alternative source: ${_selected!.name}');*/
  }

  /// Check if the currently selected source still exists and select alternative if needed
  @override
  void checkAndFixSelection([String? destroyedSourceUid]) {
    /*if (_selected == null) {
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
    }*/
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
*/

class _DatabaseApiImpl implements DatabaseApi {
  final _sourceController = SourceController();
  final _patientController = PatientController();
  @override
  ISourceController get sourceController => _sourceController;
  @override
  IPatientController get patientController => _patientController;

  Future<void> initialize() async {
    await _sourceController.initialize();
  }

  Future<void> dispose() async {
    debugPrint('---------- _DatabaseApiImpl.dispose() called');
    debugPrint(
        '---------- Calling sources.clear(), rootSources count: ${_sourceController.sources.rootSources.length}');
    await _sourceController.sources.disconnectAll();
    _sourceController.sources.clear();
    debugPrint('---------- sources.clear() completed');
    _sourceController.dispose();
    debugPrint('---------- _DatabaseApiImpl.dispose() completed');
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
    await _api!.initialize();
  }

  @override
  Future<void> dispose() async {
    debugPrint('---------- DatabasePlugin.dispose() called');
    // Unregister the page type (includes page creator)
    PageType.unregister(databasePageType.id);
    debugPrint('---------- Calling _api.dispose()');
    await _api!.dispose();
    debugPrint('---------- _api.dispose() completed');
    _api = null;
    debugPrint('---------- DatabasePlugin.dispose() completed');
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
