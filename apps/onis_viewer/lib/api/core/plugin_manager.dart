import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../core/constants.dart';
import '../../core/plugin_interface.dart';
import '../../plugins/database/database_plugin.dart';
import '../../plugins/sources/site-server/site_server_plugin.dart';
import '../../plugins/viewer/viewer_plugin.dart';

/// Observer interface for plugin manager changes
abstract class PluginManagerObserver {
  void onPluginLoaded(OnisViewerPlugin plugin);
  void onPluginUnloaded(String pluginId);
  void onError(String message);
}

/// Manages plugin discovery, loading, and lifecycle
class PluginManager {
  final Map<String, OnisViewerPlugin> _loadedPlugins = {};
  final List<OnisViewerPlugin> _builtinPlugins = [];
  final List<String> _pluginDirectories = [];
  final StreamController<String> _logController =
      StreamController<String>.broadcast();

  // Public API registry (pluginId -> api object)
  final Map<String, Object> _publicApis = {};

  // Stream controllers for reactive updates
  final StreamController<OnisViewerPlugin> _pluginLoadedController =
      StreamController<OnisViewerPlugin>.broadcast();
  final StreamController<String> _pluginUnloadedController =
      StreamController<String>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  // Observer pattern
  final List<PluginManagerObserver> _observers = [];

  // Getters
  List<OnisViewerPlugin> get loadedPlugins =>
      List.unmodifiable(_loadedPlugins.values);
  List<OnisViewerPlugin> get builtinPlugins =>
      List.unmodifiable(_builtinPlugins);
  Stream<String> get onLog => _logController.stream;

  // Streams
  Stream<OnisViewerPlugin> get onPluginLoaded => _pluginLoadedController.stream;
  Stream<String> get onPluginUnloaded => _pluginUnloadedController.stream;
  Stream<String> get onError => _errorController.stream;

  /// Initialize the plugin manager
  Future<void> initialize() async {
    try {
      _log('Initializing PluginManager...');

      // Initialize built-in plugins
      await _initializeBuiltinPlugins();

      // Add default plugin directories
      await _addPluginDirectory(OnisViewerConstants.pluginDirectory);

      // Discover and load plugins
      await discoverPlugins();

      _log('PluginManager initialized with ${_loadedPlugins.length} plugins');
    } catch (e) {
      _log('Error initializing PluginManager: $e');
    }
  }

  /// Initialize built-in plugins
  Future<void> _initializeBuiltinPlugins() async {
    try {
      // Database plugin
      final databasePlugin = DatabasePlugin();
      await registerPlugin(databasePlugin);
      _builtinPlugins.add(databasePlugin);

      // Viewer plugin
      final viewerPlugin = ViewerPlugin();
      await registerPlugin(viewerPlugin);
      _builtinPlugins.add(viewerPlugin);

      // Site Server plugin
      final siteServerPlugin = SiteServerPlugin();
      await registerPlugin(siteServerPlugin);
      _builtinPlugins.add(siteServerPlugin);

      debugPrint(
          'Built-in plugins initialized: ${_builtinPlugins.length} plugins');
    } catch (e) {
      debugPrint('Error initializing built-in plugins: $e');
    }
  }

  /// Add a plugin directory to search for plugins
  Future<void> addPluginDirectory(String directoryPath) async {
    await _addPluginDirectory(directoryPath);
  }

  /// Discover plugins in all registered directories
  Future<void> discoverPlugins() async {
    _log('Discovering plugins...');

    for (final directory in _pluginDirectories) {
      await _discoverPluginsInDirectory(directory);
    }
  }

  /// Load a specific plugin
  Future<void> loadPlugin(String pluginPath) async {
    try {
      _log('Loading plugin: $pluginPath');

      // Validate plugin path
      if (!await File(pluginPath).exists()) {
        throw Exception('Plugin file not found: $pluginPath');
      }

      // Load the plugin (this would involve dynamic loading in a real implementation)
      // For now, we'll simulate plugin loading
      final plugin = await _loadPluginFromPath(pluginPath);

      if (plugin != null) {
        await registerPlugin(plugin);
        _loadedPlugins[plugin.id] = plugin;
        _log('Plugin loaded successfully: ${plugin.name}');
      }
    } catch (e) {
      _log('Error loading plugin $pluginPath: $e');
    }
  }

  /// Register a plugin
  Future<void> registerPlugin(OnisViewerPlugin plugin) async {
    try {
      if (!plugin.isValid) {
        throw Exception('Invalid plugin configuration');
      }

      if (_loadedPlugins.containsKey(plugin.id)) {
        throw Exception('Plugin ${plugin.id} is already registered');
      }

      // Initialize the plugin
      await plugin.initialize();

      // Register the plugin
      _loadedPlugins[plugin.id] = plugin;

      // Capture public API if provided
      final api = plugin.publicApi;
      if (api != null) {
        _publicApis[plugin.id] = api;
      }

      // Page types are now registered directly by plugins with PageType.register()

      // Notify observers
      _notifyPluginLoaded(plugin);

      _log('Registered plugin: ${plugin.name}');
    } catch (e) {
      _notifyError('Failed to register plugin ${plugin.id}: $e');
    }
  }

  /// Unload a plugin
  Future<void> unloadPlugin(String pluginId) async {
    try {
      _log('Unloading plugin: $pluginId');

      await unregisterPlugin(pluginId);
      _loadedPlugins.remove(pluginId);

      _log('Plugin unloaded: $pluginId');
    } catch (e) {
      _log('Error unloading plugin $pluginId: $e');
    }
  }

  /// Unregister a plugin
  Future<void> unregisterPlugin(String pluginId) async {
    final plugin = _loadedPlugins[pluginId];
    if (plugin != null) {
      try {
        // Page types are now unregistered directly by plugins with PageType.unregister()

        // Dispose the plugin
        await plugin.dispose();

        // Remove the plugin
        _loadedPlugins.remove(pluginId);
        _publicApis.remove(pluginId);

        // Notify observers
        _notifyPluginUnloaded(pluginId);

        _log('Unregistered plugin: $pluginId');
      } catch (e) {
        _notifyError('Failed to unregister plugin $pluginId: $e');
      }
    }
  }

  /// Reload a plugin
  Future<void> reloadPlugin(String pluginId) async {
    try {
      _log('Reloading plugin: $pluginId');

      await unloadPlugin(pluginId);
      // In a real implementation, we would reload from the original path
      // For now, we'll just log the action
      _log('Plugin reloaded: $pluginId');
    } catch (e) {
      _log('Error reloading plugin $pluginId: $e');
    }
  }

  /// Get a plugin by ID
  OnisViewerPlugin? getPlugin(String pluginId) {
    return _loadedPlugins[pluginId];
  }

  /// Get a plugin public API by plugin ID and type
  T? getPublicApi<T>(String pluginId) {
    final api = _publicApis[pluginId];
    if (api == null) return null;
    if (api is T) return api as T;
    return null;
  }

  /// Get plugin information
  Map<String, dynamic> getPluginInfo(String pluginId) {
    final plugin = _loadedPlugins[pluginId];
    if (plugin != null) {
      return {
        'id': plugin.id,
        'name': plugin.name,
        'version': plugin.version,
        'description': plugin.description,
        'author': plugin.author,
        'isValid': plugin.isValid,
      };
    }
    return {};
  }

  /// Get all plugin information
  List<Map<String, dynamic>> getAllPluginInfo() {
    return _loadedPlugins.keys.map(getPluginInfo).toList();
  }

  /// Validate a plugin
  bool validatePlugin(OnisViewerPlugin plugin) {
    try {
      // Check basic requirements
      if (!plugin.isValid) {
        _log('Plugin validation failed: Invalid configuration');
        return false;
      }

      // Check for conflicts with existing plugins
      if (_loadedPlugins.containsKey(plugin.id)) {
        _log('Plugin validation failed: ID conflict with ${plugin.id}');
        return false;
      }

      _log('Plugin validation passed: ${plugin.name}');
      return true;
    } catch (e) {
      _log('Plugin validation error: $e');
      return false;
    }
  }

  /// Add an observer
  void addObserver(PluginManagerObserver observer) {
    if (!_observers.contains(observer)) {
      _observers.add(observer);
    }
  }

  /// Remove an observer
  void removeObserver(PluginManagerObserver observer) {
    _observers.remove(observer);
  }

  /// Add a plugin directory
  Future<void> _addPluginDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (await directory.exists()) {
      _pluginDirectories.add(directoryPath);
      _log('Added plugin directory: $directoryPath');
    } else {
      _log('Plugin directory not found: $directoryPath');
    }
  }

  /// Discover plugins in a specific directory
  Future<void> _discoverPluginsInDirectory(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        _log('Plugin directory not found: $directoryPath');
        return;
      }

      final entities = await directory.list().toList();

      for (final entity in entities) {
        if (entity is File) {
          final extension = path.extension(entity.path);
          if (OnisViewerConstants.supportedPluginExtensions
              .contains(extension)) {
            await loadPlugin(entity.path);
          }
        } else if (entity is Directory) {
          // Check if directory contains a plugin manifest
          final manifestPath =
              path.join(entity.path, OnisViewerConstants.pluginManifestFile);
          if (await File(manifestPath).exists()) {
            await loadPlugin(manifestPath);
          }
        }
      }
    } catch (e) {
      _log('Error discovering plugins in $directoryPath: $e');
    }
  }

  /// Load a plugin from a file path
  Future<OnisViewerPlugin?> _loadPluginFromPath(String pluginPath) async {
    try {
      // In a real implementation, this would involve:
      // 1. Reading the plugin manifest file
      // 2. Loading the plugin code dynamically
      // 3. Instantiating the plugin class
      // 4. Validating the plugin

      // For now, we'll return null to indicate no plugin was loaded
      // This will be implemented when we add actual plugin loading
      _log('Plugin loading not yet implemented for: $pluginPath');
      return null;
    } catch (e) {
      _log('Error loading plugin from path $pluginPath: $e');
      return null;
    }
  }

  /// Log a message
  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] PluginManager: $message';
    debugPrint(logMessage);
    _logController.add(logMessage);
  }

  /// Notify observers of plugin loaded
  void _notifyPluginLoaded(OnisViewerPlugin plugin) {
    for (final observer in _observers) {
      observer.onPluginLoaded(plugin);
    }
    _pluginLoadedController.add(plugin);
  }

  /// Notify observers of plugin unloaded
  void _notifyPluginUnloaded(String pluginId) {
    for (final observer in _observers) {
      observer.onPluginUnloaded(pluginId);
    }
    _pluginUnloadedController.add(pluginId);
  }

  /// Notify observers of errors
  void _notifyError(String message) {
    for (final observer in _observers) {
      observer.onError(message);
    }
    _errorController.add(message);
  }

  /// Dispose the plugin manager
  Future<void> dispose() async {
    try {
      _log('Disposing PluginManager...');

      // Unload all plugins
      for (final pluginId in _loadedPlugins.keys.toList()) {
        await unloadPlugin(pluginId);
      }

      // Dispose stream controllers
      await _logController.close();
      await _pluginLoadedController.close();
      await _pluginUnloadedController.close();
      await _errorController.close();

      // Clear observers
      _observers.clear();
      _publicApis.clear();

      _log('PluginManager disposed');
    } catch (e) {
      debugPrint('Error disposing PluginManager: $e');
    }
  }
}
