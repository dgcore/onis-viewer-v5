import 'package:flutter/material.dart';

/// Application-wide constants for ONIS Viewer
class OnisViewerConstants {
  // Application information
  static const String appName = 'ONIS Viewer';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Medical Imaging Viewer with Plugin Support';

  // Window configuration
  static const double defaultWindowWidth = 1200.0;
  static const double defaultWindowHeight = 800.0;
  static const double minWindowWidth = 800.0;
  static const double minWindowHeight = 600.0;

  // UI dimensions
  static const double statusBarHeight = 30.0;
  static const double tabButtonHeight = 30.0;
  static const double tabButtonWidth = 120.0;
  static const double windowControlSize = 30.0;
  static const double windowTitleBarHeight = 32.0;

  // Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF4CAF50);
  static const Color backgroundColor = Color(0xFF1E1E1E);
  static const Color surfaceColor = Color(0xFF2D2D2D);
  static const Color statusBarColor = Color(0xFF3C3C3C);
  static const Color tabBarColor = Color(0xFF4A4A4A);
  static const Color tabButtonColor = Color(0xFF5A5A5A);
  static const Color tabButtonActiveColor = Color(0xFF2196F3);
  static const Color textColor = Color(0xFFFFFFFF);
  static const Color textSecondaryColor = Color(0xFFB0B0B0);
  static const Color viewAreaBackgroundColor = Color(0x00000000);

  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 10.0;
  static const double paddingLarge = 24.0;
  static const double marginSmall = 4.0;
  static const double marginMedium = 8.0;
  static const double marginLarge = 16.0;

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Plugin configuration
  static const String pluginDirectory = 'plugins';
  static const String pluginManifestFile = 'plugin.yaml';
  static const List<String> supportedPluginExtensions = ['.dart', '.yaml'];

  // File paths
  static const String configDirectory = 'config';
  static const String logsDirectory = 'logs';
  static const String cacheDirectory = 'cache';
  static const String tempDirectory = 'temp';

  // Error messages
  static const String errorPluginNotFound = 'Plugin not found';
  static const String errorPluginLoadFailed = 'Failed to load plugin';
  static const String errorPageNotFound = 'Page not found';
  static const String errorInvalidPageType = 'Invalid page type';

  // Success messages
  static const String successPluginLoaded = 'Plugin loaded successfully';
  static const String successPageSwitched = 'Page switched successfully';

  // Default values
  static const String defaultPageId = 'database';
  static const int maxRecentPages = 10;
  static const int maxPluginInstances = 100;

  // Feature flags
  static const bool enablePluginHotReload = true;
  static const bool enablePageCaching = true;
  static const bool enableDebugMode = false;
}
