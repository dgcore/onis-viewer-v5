import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/core/page_manager.dart';
import '../api/core/plugin_manager.dart';
import '../api/ov_api.dart';
import '../core/constants.dart';
import '../core/page_type.dart';
import '../core/plugin_interface.dart';
import '../ui/content_area/content_area.dart';
import '../ui/status_bar/status_bar.dart';
import '../ui/window/custom_window_frame.dart';

/// Global navigator key to access app state
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Main ONIS Viewer application widget
class OnisViewerApp extends StatefulWidget {
  const OnisViewerApp({super.key});

  @override
  State<OnisViewerApp> createState() => _OnisViewerAppState();

  /// Global method to handle app quit with clean exit
  /// This can be called from anywhere in the app
  static Future<void> quitWithCleanExit() async {
    debugPrint('quitWithCleanExit called');
    final context = navigatorKey.currentContext;
    debugPrint(
        'navigatorKey.currentContext: ${context != null ? 'found' : 'null'}');
    if (context != null) {
      final appState = context.findAncestorStateOfType<_OnisViewerAppState>();
      debugPrint('appState found: ${appState != null ? 'yes' : 'no'}');
      if (appState != null) {
        debugPrint('Calling handleQuitRequest on appState');
        await appState.handleQuitRequest();
        // After clean exit, close the app
        debugPrint('Clean exit completed, calling SystemNavigator.pop()');
        SystemNavigator.pop();
      } else {
        // Fallback: close immediately if app state not found
        debugPrint('App state not found, closing immediately');
        SystemNavigator.pop();
      }
    } else {
      // Fallback: close immediately if context not found
      debugPrint('Context not found, closing immediately');
      SystemNavigator.pop();
    }
  }
}

class _OnisViewerAppState extends State<OnisViewerApp>
    with WidgetsBindingObserver
    implements PageManagerObserver, PluginManagerObserver {
  final OVApi _api = OVApi();
  bool _isInitialized = false;
  List<PageType> _availablePages = [];
  PageType? _currentPage;
  bool _isShuttingDown = false;
  bool _showQuitDialog = false;
  String _quitMessage = 'Disconnecting from sources...';

  @override
  void initState() {
    super.initState();
    debugPrint('Adding WidgetsBindingObserver');
    WidgetsBinding.instance.addObserver(this);
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
    debugPrint('Removing WidgetsBindingObserver');
    _api.pages.removeObserver(this);
    _api.plugins.removeObserver(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('App lifecycle state changed to: $state');
    debugPrint(
        'Lifecycle method called - state: $state, _isShuttingDown: $_isShuttingDown');

    // Handle app shutdown - try multiple states for reliability
    if ((state == AppLifecycleState.detached ||
            state == AppLifecycleState.paused) &&
        !_isShuttingDown) {
      debugPrint(
          'Detected app shutdown state: $state, _isShuttingDown: $_isShuttingDown');
      _isShuttingDown = true;
      _showQuitDialog = true;
      _quitMessage = 'Disconnecting from sources...';
      setState(() {});
      debugPrint('Application is shutting down, performing clean exit...');

      // Perform clean exit and wait for it to complete
      // Use a more robust approach that prevents immediate exit
      _performCleanExit().then((_) {
        _quitMessage = 'Application will close shortly...';
        setState(() {});
        debugPrint('Clean exit completed, allowing app to exit');
      }).catchError((error) {
        debugPrint('Error during clean exit: $error');
      });
    } else {
      debugPrint(
          'Not triggering clean exit - state: $state, _isShuttingDown: $_isShuttingDown');
    }
  }

  /// Perform clean exit and wait for completion
  Future<void> _performCleanExit() async {
    try {
      await _api.cleanExit();
      debugPrint('Clean exit completed successfully');
    } catch (error) {
      debugPrint('Error during clean exit: $error');
    }
  }

  /// Handle manual quit request (can be called from UI)
  Future<void> handleQuitRequest() async {
    if (!_isShuttingDown) {
      _isShuttingDown = true;
      _showQuitDialog = true;
      _quitMessage = 'Disconnecting from sources...';
      setState(() {});
      debugPrint('Manual quit requested, performing clean exit...');

      // Update message during clean exit
      _quitMessage = 'Disconnecting from sources...';
      setState(() {});

      await _performCleanExit();

      // Update final message
      _quitMessage = 'Application will close shortly...';
      setState(() {});

      // After clean exit, we can safely exit the app
      debugPrint('Clean exit completed, app can now exit safely');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
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
      home: Stack(
        children: [
          _buildMainContent(),
          // Quit dialog overlay
          if (_showQuitDialog) _buildModalQuitDialog(),
        ],
      ),
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

  /// Build a modal quit dialog
  Widget _buildModalQuitDialog() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Modal barrier - blocks all interaction with background
          ModalBarrier(
            color: Colors.black.withOpacity(0.5),
          ),
          // Dialog content
          Center(
            child: Container(
              padding: const EdgeInsets.all(OnisViewerConstants.paddingLarge),
              width: 300,
              constraints: const BoxConstraints(
                minHeight: 200,
                maxHeight: 250,
              ),
              decoration: BoxDecoration(
                color: OnisViewerConstants.surfaceColor,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: OnisViewerConstants.tabButtonColor,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App icon
                  Icon(
                    Icons.warning_amber,
                    size: 40,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: OnisViewerConstants.marginMedium),

                  // Quit message
                  Text(
                    _quitMessage,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: OnisViewerConstants.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: OnisViewerConstants.marginMedium),

                  // Loading indicator
                  const LinearProgressIndicator(
                    color: OnisViewerConstants.primaryColor,
                    backgroundColor: OnisViewerConstants.tabButtonColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
