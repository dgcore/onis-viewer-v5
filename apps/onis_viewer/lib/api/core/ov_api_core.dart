import 'dart:async';

import 'package:flutter/material.dart';
import 'package:onis_viewer/api/core/page_manager.dart';
import 'package:onis_viewer/api/core/plugin_manager.dart';
import 'package:onis_viewer/api/graphics/managers/render_type_manager.dart';
import 'package:onis_viewer/api/graphics/managers/support_set_manager.dart';
import 'package:onis_viewer/api/services/message_service.dart';
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
  late final OsSContainerSupportSetManager _containerSupportSetManager;

  // Services
  late final OsMessageService _messageService;

  // Getters for API modules
  PageManager get pages => _pageManager;
  PluginManager get plugins => _pluginManager;
  ViewTypeManager get viewTypes => _viewTypeManager;
  OsRenderTypeManager get renderTypes => _renderTypeManager;
  OsMessageService get messages => _messageService;
  OsSContainerSupportSetManager get containerSupportSets =>
      _containerSupportSetManager;

  /// Initialize the API with all modules
  Future<void> initialize() async {
    try {
      // Initialize modules
      _viewTypeManager = ViewTypeManager();
      _pageManager = PageManager();
      _pluginManager = PluginManager();
      _renderTypeManager = OsRenderTypeManager();
      _containerSupportSetManager = OsSContainerSupportSetManager();

      // Initialize services
      _messageService = OsMessageService();

      // Initialize modules
      _renderTypeManager.initialize();
      _viewTypeManager.initialize();
      _containerSupportSetManager.initialize();
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
    _containerSupportSetManager.dispose();
    debugPrint('OVApi disposed');
  }

  /// Clean exit: disconnect all sources before disposing
  /// This should be called during application shutdown
  Future<void> cleanExit() async {
    await _pluginManager.dispose();
  }
}
