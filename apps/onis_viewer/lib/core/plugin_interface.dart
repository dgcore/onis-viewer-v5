import 'package:flutter/material.dart';

/// Abstract interface for ONIS Viewer plugins.
/// All plugins must implement this interface to be recognized by the application.
abstract class OnisViewerPlugin {
  /// Unique identifier for the plugin
  String get id;

  /// Human-readable name for the plugin
  String get name;

  /// Version of the plugin
  String get version;

  /// Description of what the plugin does
  String get description;

  /// Author of the plugin
  String get author;

  /// Plugin icon (optional)
  IconData? get icon;

  /// Plugin color theme (optional)
  Color? get color;

  /// Initialize the plugin
  /// Called when the plugin is loaded
  Future<void> initialize();

  /// Clean up plugin resources
  /// Called when the plugin is unloaded
  Future<void> dispose();

  /// Get plugin metadata
  Map<String, dynamic> get metadata => {
        'id': id,
        'name': name,
        'version': version,
        'description': description,
        'author': author,
      };

  /// Validate plugin configuration
  /// Returns true if the plugin is properly configured
  bool get isValid => id.isNotEmpty && name.isNotEmpty && version.isNotEmpty;

  /// Optional: a public API object that can be obtained via the PluginManager
  /// Consumers can fetch it using getPublicApi<T>(pluginId)
  Object? get publicApi => null;

  @override
  String toString() =>
      'OnisViewerPlugin(id: $id, name: $name, version: $version)';
}

/// Exception thrown when plugin operations fail
class PluginException implements Exception {
  final String message;
  final String? pluginId;
  final dynamic originalError;

  const PluginException(this.message, {this.pluginId, this.originalError});

  @override
  String toString() {
    final prefix = pluginId != null ? 'Plugin $pluginId: ' : 'Plugin: ';
    return '$prefix$message${originalError != null ? ' ($originalError)' : ''}';
  }
}
