import 'dart:async';

import 'package:flutter/material.dart';

import 'page_manager.dart';
import 'plugin_manager.dart';

/// Core OVApi singleton that coordinates all API modules
class OVApi {
  static final OVApi _instance = OVApi._internal();
  factory OVApi() => _instance;
  OVApi._internal();

  // API modules
  late final PageManager _pageManager;
  late final PluginManager _pluginManager;

  // Getters for API modules
  PageManager get pages => _pageManager;
  PluginManager get plugins => _pluginManager;

  /// Initialize the API with all modules
  Future<void> initialize() async {
    try {
      // Initialize modules
      _pageManager = PageManager();
      _pluginManager = PluginManager();

      // Initialize modules
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
    // Dispose modules (they will handle their own stream disposal)
    await _pageManager.dispose();
    await _pluginManager.dispose();

    debugPrint('OVApi disposed');
  }
}
