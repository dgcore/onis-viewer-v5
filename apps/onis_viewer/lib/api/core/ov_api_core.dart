import 'dart:async';

import 'package:flutter/material.dart';
import 'package:onis_viewer/api/core/page_manager.dart';
import 'package:onis_viewer/api/core/plugin_manager.dart';
import 'package:onis_viewer/api/graphics/managers/render_type_manager.dart';
import 'package:onis_viewer/api/view_type/view_type_manager.dart';

/// Core OVApi singleton that coordinates all API modules
class OVApi {
  static final OVApi _instance = OVApi._internal();
  factory OVApi() => _instance;
  OVApi._internal();

  // API modules
  late final PageManager _pageManager;
  late final PluginManager _pluginManager;
  late final ViewTypeManager _viewTypeManager;
  late final OsRenderTypeManager _renderTypeManager;

  // Getters for API modules
  PageManager get pages => _pageManager;
  PluginManager get plugins => _pluginManager;
  ViewTypeManager get viewTypes => _viewTypeManager;
  OsRenderTypeManager get renderTypes => _renderTypeManager;

  /// Initialize the API with all modules
  Future<void> initialize() async {
    try {
      // Initialize modules
      _viewTypeManager = ViewTypeManager();
      _pageManager = PageManager();
      _pluginManager = PluginManager();
      _renderTypeManager = OsRenderTypeManager();

      // Initialize modules
      _renderTypeManager.initialize();
      _viewTypeManager.initialize();
      await _pageManager.initialize();
      await _pluginManager.initialize();

      // Sync page manager with page types registered by plugins
      _pageManager.syncWithRegisteredTypes();

      debugPrint('OVApi initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize OVApi: $e');
    }
  }

  /// Dispose the API and all modules
  Future<void> dispose() async {
    await _pageManager.dispose();
    await _pluginManager.dispose();
    _viewTypeManager.dispose();
    debugPrint('OVApi disposed');
  }

  /// Clean exit: disconnect all sources before disposing
  /// This should be called during application shutdown
  Future<void> cleanExit() async {
    await _pluginManager.dispose();
  }
}
