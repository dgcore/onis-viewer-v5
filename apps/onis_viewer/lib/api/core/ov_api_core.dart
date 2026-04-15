import 'dart:async';

import 'package:flutter/material.dart';
import 'package:onis_viewer/api/core/plugin_manager.dart';
import 'package:onis_viewer/api/graphics/managers/render_type_manager.dart';
import 'package:onis_viewer/api/graphics/managers/support_set_manager.dart';
import 'package:onis_viewer/api/managers/page_type_manager.dart';
import 'package:onis_viewer/api/services/message_service.dart';
import 'package:onis_viewer/api/view_type/view_type_manager.dart';
import 'package:onis_viewer/core/monitor/monitor_config.dart';
import 'package:onis_viewer/core/monitor/page_type.dart';

/// Core OVApi singleton that coordinates all API modules
class OVApi {
  static final OVApi _instance = OVApi._internal();
  factory OVApi() => _instance;
  OVApi._internal();

  // API modules
  //late final PageManager _pageManager;
  late final PluginManager _pluginManager;
  late final ViewTypeManager _viewTypeManager;
  late final OsRenderTypeManager _renderTypeManager;
  late final OsSContainerSupportSetManager _containerSupportSetManager;

  // Managers:
  final PageTypeManager _pageTypeManager = PageTypeManager('page_type_manager');

  //monitor:
  final OsMonitorConfig _monitorConfig = OsMonitorConfig();
  final OsMonitorConfig _nextMonitorConfig = OsMonitorConfig();

  final List<OsPageType> _pageTypes = [];

  // Services
  late final OsMessageService _messageService;

  // Getters for API modules
  PageTypeManager get pageTypes => _pageTypeManager;
  //PageManager get pages => _pageManager;
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
      //_pageManager = PageManager();
      _pluginManager = PluginManager();
      _renderTypeManager = OsRenderTypeManager();
      _containerSupportSetManager = OsSContainerSupportSetManager();
      //_monitorConfig.initDefault(_pageTypes);
      //_nextMonitorConfig.initDefault(_pageTypes);

      // Initialize services
      _messageService = OsMessageService();

      // Initialize modules
      _renderTypeManager.initialize();
      _viewTypeManager.initialize();
      _containerSupportSetManager.initialize();

      _monitorInit();

      //await _pageManager.initialize();
      await _pluginManager.initialize();

      // Sync page manager with page types registered by plugins
      //_pageManager.syncWithRegisteredTypes();

      debugPrint('OVApi initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize OVApi: $e');
    }
  }

  /// Dispose the API and all modules
  Future<void> dispose() async {
    //await _pageManager.dispose();
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

  //-----------------------------------------------------------------------
  //monitors
  //-----------------------------------------------------------------------

  OsMonitorConfig? get monitorConfiguration {
    return _monitorConfig;
  }

  OsMonitorConfig? get nextMonitorConfiguration {
    return _nextMonitorConfig;
  }

  void _monitorInit() {
    /*onis::xml::pdoc_ptr document = app->get_system_preference_pdocument();
		if (document != null) {
      _nextMonitorConfig.initFromDocument(document);
      currentMonitorConfig.initFromDocument(document);
    } else {*/
    _nextMonitorConfig.detectMonitors();
    _monitorConfig.detectMonitors();
    //}

    /*bool first = true;
	List<OsMonitor> monitors = _monitorConfig.getMonitors();
  for (OsMonitor monitor in monitors) {
    if (monitor.isActive()) {
      monitor.createWindow(!first, true);
      if (first) _monitorConfig.setCurrentMonitor(monitor);
      first = false;
    }
  }*/
  }
}
