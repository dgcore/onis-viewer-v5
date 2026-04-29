import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:onis_viewer/api/core/plugin_manager.dart';
import 'package:onis_viewer/api/graphics/managers/render_type_manager.dart';
import 'package:onis_viewer/api/graphics/managers/support_set_manager.dart';
import 'package:onis_viewer/api/managers/page_type_manager.dart';
import 'package:onis_viewer/api/services/message_service.dart';
import 'package:onis_viewer/api/view_type/view_type_manager.dart';
import 'package:onis_viewer/backend/backend_service.dart';
import 'package:onis_viewer/core/monitor/monitor_config.dart';

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
  final OsPageTypeManager _pageTypeManager = OsPageTypeManager();

  //monitor:
  final OsMonitorConfig _monitorConfig = OsMonitorConfig();
  final OsMonitorConfig _nextMonitorConfig = OsMonitorConfig();

  //final List<OsPageType> _pageTypes = [];

  // Services
  late final OsMessageService _messageService;
  late final OnisBackendService _backendService;

  /// This Flutter engine's [WindowController.windowId] (`0` = main window).
  /// Set during [initialize]; reads as `0` before that.
  int _flutterEngineInstanceId = 0;

  bool _isInitialized = false;
  int _initializeRefCount = 0;
  Future<void>? _initializingFuture;

  // Getters for API modules
  OsPageTypeManager get pageTypes => _pageTypeManager;
  //PageManager get pages => _pageManager;
  PluginManager get plugins => _pluginManager;
  ViewTypeManager get viewTypes => _viewTypeManager;
  OsRenderTypeManager get renderTypes => _renderTypeManager;
  OsMessageService get messages => _messageService;
  OnisBackendService get backend => _backendService;

  /// Same as the `flutterEngineInstanceId` argument passed to [initialize] in this isolate.
  int get flutterEngineInstanceId => _flutterEngineInstanceId;
  OsSContainerSupportSetManager get containerSupportSets =>
      _containerSupportSetManager;

  /// Initialize the API with all modules.
  ///
  /// [flutterEngineInstanceId] is this engine's id ([WindowController.windowId]):
  /// `0` for the main window, or the value from `multi_window` launch args for a
  /// secondary window. Omit or pass `null` for the main window.
  Future<void> initialize({int? flutterEngineInstanceId}) async {
    _initializeRefCount++;
    if (_isInitialized) {
      return;
    }
    _initializingFuture ??= _performInitialize(flutterEngineInstanceId);
    try {
      await _initializingFuture;
    } catch (e) {
      _initializeRefCount--;
      if (_initializeRefCount < 0) {
        _initializeRefCount = 0;
      }
      rethrow;
    }
  }

  Future<void> _performInitialize(int? flutterEngineInstanceId) async {
    try {
      _flutterEngineInstanceId = flutterEngineInstanceId ?? 0;

      // Initialize modules
      _viewTypeManager = ViewTypeManager();
      _pluginManager = PluginManager();
      _renderTypeManager = OsRenderTypeManager();
      _containerSupportSetManager = OsSContainerSupportSetManager();

      // Initialize services
      _messageService = OsMessageService();
      _backendService = OnisBackendService();

      // Initialize modules
      _renderTypeManager.initialize();
      _viewTypeManager.initialize();
      _containerSupportSetManager.initialize();
      await _monitorInit();
      await _pluginManager.initialize();
      _isInitialized = true;
      debugPrint('OVApi initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize OVApi: $e');
      rethrow;
    } finally {
      _initializingFuture = null;
    }
  }

  /// Dispose the API and all modules
  Future<void> dispose() async {
    if (_initializeRefCount > 0) {
      _initializeRefCount--;
    }
    if (_initializeRefCount > 0 || !_isInitialized) {
      return;
    }
    //await _pageManager.dispose();
    await _pluginManager.dispose();
    _viewTypeManager.dispose();
    _containerSupportSetManager.dispose();
    _messageService.dispose();
    _backendService.dispose();
    _isInitialized = false;
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

  Future<void> _monitorInit() async {
    /*onis::xml::pdoc_ptr document = app->get_system_preference_pdocument();
		if (document != null) {
      _nextMonitorConfig.initFromDocument(document);
      currentMonitorConfig.initFromDocument(document);
    } else {*/
    await _nextMonitorConfig.detectMonitors();
    await _monitorConfig.detectMonitors();
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

  /// Registers [DesktopMultiWindow.setMethodHandler] so this engine receives
  /// cross-window messages. Call after [initialize]. Optional [onUnhandled]
  /// chains `onis/backend_identity` or other methods.
  /*void attachMultiWindowMessageHandler(
    [Future<dynamic> Function(MethodCall call, int fromWindowId)?
        onUnhandled,
  ]) {
    if (kIsWeb) {
      return;
    }
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return;
    }
    DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
      if (_messageService.tryHandleWindowMethodCall(call)) {
        return null;
      }
      if (onUnhandled != null) {
        return onUnhandled(call, fromWindowId);
      }
      return null;
    });
  }*/
}
