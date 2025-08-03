import 'package:flutter/material.dart';

import '../api/core/page_manager.dart';
import '../api/core/plugin_manager.dart';
import '../api/ov_api.dart';
import '../core/constants.dart';
import '../core/page_type.dart';
import '../core/plugin_interface.dart';
import '../ui/content_area/content_area.dart';
import '../ui/status_bar/status_bar.dart';
import '../ui/window/custom_window_frame.dart';

/// Main ONIS Viewer application widget
class OnisViewerApp extends StatefulWidget {
  const OnisViewerApp({super.key});

  @override
  State<OnisViewerApp> createState() => _OnisViewerAppState();
}

class _OnisViewerAppState extends State<OnisViewerApp>
    implements PageManagerObserver, PluginManagerObserver {
  final OVApi _api = OVApi();
  bool _isInitialized = false;
  List<PageType> _availablePages = [];
  PageType? _currentPage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize the API
      await _api.initialize();

      // Set up direct observers
      _api.pages.addObserver(this);
      _api.plugins.addObserver(this);

      // Set up page change listener
      _api.pages.onPageChanged.listen((pageType) {
        setState(() {
          _currentPage = pageType;
        });
      });

      // Set initial page
      if (_api.pages.availablePages.isNotEmpty) {
        _currentPage =
            _api.pages.currentPage ?? _api.pages.availablePages.first;
      }

      // Set initial state
      if (mounted) {
        setState(() {
          _availablePages = _api.pages.availablePages;
          _isInitialized = true;
        });
      }

      debugPrint('OnisViewerApp initialized successfully');
    } catch (e) {
      debugPrint('Error initializing OnisViewerApp: $e');
    }
  }

  @override
  void dispose() {
    _api.pages.removeObserver(this);
    _api.plugins.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: OnisViewerConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: OnisViewerConstants.primaryColor,
          secondary: OnisViewerConstants.secondaryColor,
          surface: OnisViewerConstants.surfaceColor,
        ),
        useMaterial3: true,
      ),
      home: _buildMainContent(),
    );
  }

  /// Build the main content widget
  Widget _buildMainContent() {
    if (!_isInitialized) {
      return _buildLoadingScreen();
    }

    return CustomWindowFrame(
      title: OnisViewerConstants.appName,
      child: Column(
        children: [
          // Main content area
          Expanded(
            child: ContentArea(),
          ),

          // Status bar with tabs
          StatusBar(
            availablePages: _availablePages,
            currentPage: _currentPage,
            onPageSelected: _onPageSelected,
            additionalWidgets: _buildStatusBarWidgets(),
          ),
        ],
      ),
    );
  }

  /// Build loading screen
  Widget _buildLoadingScreen() {
    return Material(
      color: OnisViewerConstants.backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon
            Icon(
              Icons.medical_services,
              size: 80,
              color: OnisViewerConstants.primaryColor,
            ),
            const SizedBox(height: OnisViewerConstants.marginLarge),

            // App title
            Text(
              OnisViewerConstants.appName,
              style: const TextStyle(
                color: OnisViewerConstants.textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: OnisViewerConstants.marginSmall),

            // App description
            Text(
              OnisViewerConstants.appDescription,
              style: const TextStyle(
                color: OnisViewerConstants.textSecondaryColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: OnisViewerConstants.marginLarge),

            // Loading indicator
            const CircularProgressIndicator(
              color: OnisViewerConstants.primaryColor,
            ),
            const SizedBox(height: OnisViewerConstants.marginMedium),

            // Loading text
            const Text(
              'Initializing...',
              style: TextStyle(
                color: OnisViewerConstants.textSecondaryColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build additional status bar widgets
  List<Widget> _buildStatusBarWidgets() {
    return []; // Removed plugin and page count indicators
  }

  /// Handle page selection
  void _onPageSelected(PageType pageType) {
    _api.pages.switchToPage(pageType);
  }

  // PageManagerObserver implementation

  @override
  void onPageChanged(PageType? oldPage, PageType newPage) {
    if (mounted) {
      setState(() {
        _currentPage = newPage;
      });
    }
  }

  @override
  void onPageAdded(PageType pageType) {
    if (mounted) {
      setState(() {
        _availablePages = _api.pages.availablePages;
      });
    }
  }

  @override
  void onPageRemoved(PageType pageType) {
    if (mounted) {
      setState(() {
        _availablePages = _api.pages.availablePages;
      });
    }
  }

  // PluginManagerObserver implementation

  @override
  void onPluginLoaded(OnisViewerPlugin plugin) {
    if (mounted) {
      setState(() {
        _availablePages = _api.pages.availablePages;
      });
    }
  }

  @override
  void onPluginUnloaded(String pluginId) {
    if (mounted) {
      setState(() {
        _availablePages = _api.pages.availablePages;
      });
    }
  }

  @override
  void onError(String message) {
    // Show error message to user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
