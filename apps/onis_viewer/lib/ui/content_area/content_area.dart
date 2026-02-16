import 'package:flutter/material.dart';

import '../../api/core/page_manager.dart';
import '../../api/ov_api.dart';
import '../../core/constants.dart';
import '../../core/page_type.dart';
import 'page_container.dart';

/// Main content area that displays the current page
class ContentArea extends StatefulWidget {
  const ContentArea({super.key});

  @override
  State<ContentArea> createState() => _ContentAreaState();
}

class _ContentAreaState extends State<ContentArea>
    implements PageManagerObserver {
  final OVApi _api = OVApi();
  PageType? _currentPage;
  // Cache of page widgets to preserve them when switching tabs
  final Map<String, Widget> _pageCache = {};

  @override
  void initState() {
    super.initState();
    _api.pages.addObserver(this);
    _currentPage = _api.pages.currentPage;
    // Pre-cache available pages
    _cacheAvailablePages();
  }

  @override
  void dispose() {
    _api.pages.removeObserver(this);
    _pageCache.clear();
    super.dispose();
  }

  /// Cache all available pages
  void _cacheAvailablePages() {
    for (final pageType in _api.pages.availablePages) {
      if (!_pageCache.containsKey(pageType.id)) {
        _pageCache[pageType.id] = PageContainer(
          pageType: pageType,
          api: _api,
          key: ValueKey(pageType.id),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: OnisViewerConstants.backgroundColor,
      child: _buildPageContent(),
    );
  }

  /// Build the page content using IndexedStack to preserve pages
  Widget _buildPageContent() {
    if (_api.pages.availablePages.isEmpty) {
      return _buildNoPageWidget();
    }

    // Ensure all pages are cached
    _cacheAvailablePages();

    // Find the index of the current page
    final currentIndex = _currentPage != null
        ? _api.pages.availablePages
            .indexWhere((page) => page.id == _currentPage!.id)
        : 0;

    if (currentIndex < 0 || currentIndex >= _api.pages.availablePages.length) {
      return _buildNoPageWidget();
    }

    // Use IndexedStack to preserve all pages (only the current one is visible)
    return IndexedStack(
      index: currentIndex,
      children: _api.pages.availablePages.map((pageType) {
        return _pageCache[pageType.id] ?? _buildNoPageWidget();
      }).toList(),
    );
  }

  /// Build widget when no page is selected
  Widget _buildNoPageWidget() {
    return Container(
      color: OnisViewerConstants.backgroundColor,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dashboard,
              size: 64,
              color: OnisViewerConstants.textSecondaryColor,
            ),
            SizedBox(height: OnisViewerConstants.marginMedium),
            Text(
              'No page selected',
              style: TextStyle(
                color: OnisViewerConstants.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: OnisViewerConstants.marginSmall),
            Text(
              'Select a page from the tabs below',
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

  // PageManagerObserver implementation

  @override
  void onPageChanged(PageType? oldPage, PageType newPage) {
    if (mounted) {
      setState(() {
        _currentPage = newPage;
        // Ensure the new page is cached
        if (!_pageCache.containsKey(newPage.id)) {
          _pageCache[newPage.id] = PageContainer(
            pageType: newPage,
            api: _api,
            key: ValueKey(newPage.id),
          );
        }
      });
    }
  }

  @override
  void onPageAdded(PageType pageType) {
    // Handle page added event
    debugPrint('Page added in ContentArea: ${pageType.name}');
    // Cache the new page
    if (mounted && !_pageCache.containsKey(pageType.id)) {
      _pageCache[pageType.id] = PageContainer(
        pageType: pageType,
        api: _api,
        key: ValueKey(pageType.id),
      );
      setState(() {});
    }
  }

  @override
  void onPageRemoved(PageType pageType) {
    // Handle page removed event
    debugPrint('Page removed in ContentArea: ${pageType.name}');
    // Remove from cache
    _pageCache.remove(pageType.id);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void onError(String message) {
    // Handle error event
    debugPrint('Error in ContentArea: $message');
  }
}
