import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/page_type.dart';

/// Abstract base class for all pages in the ONIS Viewer application
abstract class BasePage extends StatefulWidget {
  final PageType pageType;
  final Map<String, dynamic>? parameters;

  const BasePage({
    super.key,
    required this.pageType,
    this.parameters,
  });

  @override
  BasePageState createState() => createPageState();

  /// Create the specific page state
  BasePageState createPageState();
}

/// Abstract base state class for all pages
abstract class BasePageState<T extends BasePage> extends State<T>
    with AutomaticKeepAliveClientMixin<T> {
  // Page lifecycle state
  bool _isInitialized = false;
  bool _isDisposed = false;
  String? _errorMessage;

  // Keep alive for page caching
  @override
  bool get wantKeepAlive => true;

  // Getters
  PageType get pageType => widget.pageType;
  Map<String, dynamic>? get parameters => widget.parameters;
  bool get isInitialized => _isInitialized;
  bool get isDisposed => _isDisposed;
  String? get errorMessage => _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _disposePage();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    if (!_isInitialized) {
      return _buildLoadingWidget();
    }

    return _buildPageContent();
  }

  /// Initialize the page
  Future<void> _initializePage() async {
    try {
      await initializePage();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// Dispose the page
  Future<void> _disposePage() async {
    try {
      await disposePage();
    } catch (e) {
      debugPrint('Error disposing page ${pageType.name}: $e');
    }
  }

  /// Build the main page content
  Widget _buildPageContent() {
    return Container(
      color: OnisViewerConstants.backgroundColor,
      child: Column(
        children: [
          // Page header/toolbar
          _buildPageHeader(),

          // Main content area
          Expanded(
            child: _buildPageBody(),
          ),

          // Page footer/status
          _buildPageFooter(),
        ],
      ),
    );
  }

  /// Build the page header/toolbar
  Widget _buildPageHeader() {
    return Container(
      height: 60,
      color: OnisViewerConstants.surfaceColor,
      padding: const EdgeInsets.symmetric(
        horizontal: OnisViewerConstants.paddingMedium,
        vertical: OnisViewerConstants.paddingSmall,
      ),
      child: Row(
        children: [
          // Page icon and title
          Icon(
            pageType.icon,
            color: pageType.color ?? OnisViewerConstants.primaryColor,
            size: 24,
          ),
          const SizedBox(width: OnisViewerConstants.marginMedium),
          Text(
            pageType.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: OnisViewerConstants.textColor,
            ),
          ),
          const Spacer(),
          // Page-specific toolbar items
          ...buildToolbarItems(),
        ],
      ),
    );
  }

  /// Build the page body content
  Widget _buildPageBody() {
    return Container(
      color: OnisViewerConstants.backgroundColor,
      padding: const EdgeInsets.all(OnisViewerConstants.paddingMedium),
      child: buildPageContent(),
    );
  }

  /// Build the page footer/status
  Widget _buildPageFooter() {
    return Container(
      height: 30,
      color: OnisViewerConstants.surfaceColor,
      padding: const EdgeInsets.symmetric(
        horizontal: OnisViewerConstants.paddingMedium,
      ),
      child: Row(
        children: [
          // Page status
          Text(
            getPageStatus(),
            style: const TextStyle(
              fontSize: 12,
              color: OnisViewerConstants.textSecondaryColor,
            ),
          ),
          const Spacer(),
          // Page-specific footer items
          ...buildFooterItems(),
        ],
      ),
    );
  }

  /// Build loading widget
  Widget _buildLoadingWidget() {
    return Container(
      color: OnisViewerConstants.backgroundColor,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: OnisViewerConstants.primaryColor,
            ),
            SizedBox(height: OnisViewerConstants.marginMedium),
            Text(
              'Loading...',
              style: TextStyle(
                color: OnisViewerConstants.textColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error widget
  Widget _buildErrorWidget() {
    return Container(
      color: OnisViewerConstants.backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: OnisViewerConstants.marginMedium),
            Text(
              'Error loading page',
              style: const TextStyle(
                color: OnisViewerConstants.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: OnisViewerConstants.marginSmall),
            Text(
              _errorMessage ?? 'Unknown error',
              style: const TextStyle(
                color: OnisViewerConstants.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: OnisViewerConstants.marginLarge),
            ElevatedButton(
              onPressed: _retryInitialization,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// Retry page initialization
  void _retryInitialization() {
    setState(() {
      _errorMessage = null;
      _isInitialized = false;
    });
    _initializePage();
  }

  // Abstract methods that must be implemented by subclasses

  /// Initialize the page (called once when the page is created)
  Future<void> initializePage();

  /// Dispose the page (called when the page is disposed)
  Future<void> disposePage();

  /// Build the main page content
  Widget buildPageContent();

  /// Build toolbar items for the page header
  List<Widget> buildToolbarItems() => [];

  /// Build footer items for the page footer
  List<Widget> buildFooterItems() => [];

  /// Get the current page status
  String getPageStatus() => 'Ready';

  // Utility methods

  /// Show a snackbar message
  void showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red : OnisViewerConstants.primaryColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show a confirmation dialog
  Future<bool> showConfirmationDialog({
    required String title,
    required String message,
    String confirmText = 'OK',
    String cancelText = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Navigate to another page
  void navigateToPage(PageType pageType, {Map<String, dynamic>? parameters}) {
    // This will be implemented when we add navigation support
    debugPrint('Navigate to page: ${pageType.name}');
  }
}
