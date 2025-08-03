import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/page_factory.dart';
import '../../core/page_type.dart';

/// Observer interface for page manager changes
abstract class PageManagerObserver {
  void onPageChanged(PageType? oldPage, PageType newPage);
  void onPageAdded(PageType pageType);
  void onPageRemoved(PageType pageType);
  void onError(String message);
}

/// Manages page switching and page lifecycle
class PageManager {
  // Current page management
  PageType? _currentPage;
  final List<PageType> _availablePages = [];
  final List<PageType> _recentPages = [];

  // Observer pattern
  final List<PageManagerObserver> _observers = [];

  // Stream controllers for reactive updates
  final StreamController<PageType> _pageChangeController =
      StreamController<PageType>.broadcast();
  final StreamController<PageType> _pageAddedController =
      StreamController<PageType>.broadcast();
  final StreamController<PageType> _pageRemovedController =
      StreamController<PageType>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  // Getters
  PageType? get currentPage => _currentPage;
  List<PageType> get availablePages => List.unmodifiable(_availablePages);
  List<PageType> get recentPages => List.unmodifiable(_recentPages);

  // Streams
  Stream<PageType> get onPageChanged => _pageChangeController.stream;
  Stream<PageType> get onPageAdded => _pageAddedController.stream;
  Stream<PageType> get onPageRemoved => _pageRemovedController.stream;
  Stream<String> get onError => _errorController.stream;

  /// Initialize the page manager
  Future<void> initialize() async {
    try {
      // Page types will be registered by plugins during initialization
      // Set default page to null initially
      _currentPage = null;

      debugPrint('PageManager initialized');
    } catch (e) {
      _notifyError('Failed to initialize PageManager: $e');
    }
  }

  /// Sync available pages with registered page types
  void syncWithRegisteredTypes() {
    final registeredTypes = PageType.registeredTypes;
    _availablePages.clear();
    _availablePages.addAll(registeredTypes);

    // Set current page if none is set and pages are available
    if (_currentPage == null && _availablePages.isNotEmpty) {
      _currentPage = _availablePages.first;
      _recentPages.add(_currentPage!);
    }

    debugPrint(
        'PageManager synced with ${_availablePages.length} registered page types');
  }

  /// Switch to a different page
  Future<void> switchToPage(PageType pageType) async {
    if (!_availablePages.contains(pageType)) {
      _notifyError('Page type ${pageType.id} is not available');
      return;
    }

    final oldPage = _currentPage;
    _currentPage = pageType;

    // Update recent pages
    _recentPages.remove(pageType);
    _recentPages.insert(0, pageType);
    if (_recentPages.length > OnisViewerConstants.maxRecentPages) {
      _recentPages.removeLast();
    }

    // Notify observers
    _notifyPageChanged(oldPage, pageType);

    debugPrint('Switched to page: ${pageType.name}');
  }

  /// Switch to page by ID
  Future<void> switchToPageById(String pageId) async {
    final pageType = _availablePages.where((p) => p.id == pageId).firstOrNull;
    if (pageType != null) {
      await switchToPage(pageType);
    } else {
      _notifyError('Page with ID $pageId not found');
    }
  }

  /// Add a new page type and create the page (from plugins)
  void addPageType(PageType pageType) {
    if (!_availablePages.contains(pageType)) {
      // Create the page using PageFactory to ensure it's valid
      final pageWidget = PageFactory().createPage(pageType);

      if (pageWidget != null) {
        // Add the page type to available pages
        _availablePages.add(pageType);

        // Set as current page if no current page is set
        if (_currentPage == null) {
          _currentPage = pageType;
          _recentPages.add(pageType);
        }

        // Notify observers that a new page was added
        _notifyPageAdded(pageType);

        debugPrint('Added and created page: ${pageType.name}');
      } else {
        _notifyError('Failed to create page for ${pageType.name}');
      }
    }
  }

  /// Remove a page type
  void removePageType(PageType pageType) {
    if (_availablePages.remove(pageType)) {
      // If current page is being removed, switch to first available page or null
      if (_currentPage == pageType) {
        _currentPage =
            _availablePages.isNotEmpty ? _availablePages.first : null;
        if (_currentPage != null) {
          _notifyPageChanged(pageType, _currentPage!);
        }
      }

      // Notify observers that a page was removed
      _notifyPageRemoved(pageType);

      debugPrint('Removed page type: ${pageType.name}');
    }
  }

  /// Get page type by ID
  PageType? getPageTypeById(String pageId) {
    return _availablePages.where((p) => p.id == pageId).firstOrNull;
  }

  /// Check if a page type is available
  bool isPageTypeAvailable(PageType pageType) {
    return _availablePages.contains(pageType);
  }

  /// Get page type by ID
  bool isPageTypeAvailableById(String pageId) {
    return _availablePages.any((p) => p.id == pageId);
  }

  /// Add an observer
  void addObserver(PageManagerObserver observer) {
    if (!_observers.contains(observer)) {
      _observers.add(observer);
    }
  }

  /// Remove an observer
  void removeObserver(PageManagerObserver observer) {
    _observers.remove(observer);
  }

  /// Dispose the page manager
  Future<void> dispose() async {
    _observers.clear();

    // Dispose stream controllers
    await _pageChangeController.close();
    await _pageAddedController.close();
    await _pageRemovedController.close();
    await _errorController.close();

    debugPrint('PageManager disposed');
  }

  /// Notify observers of page changes
  void _notifyPageChanged(PageType? oldPage, PageType newPage) {
    for (final observer in _observers) {
      observer.onPageChanged(oldPage, newPage);
    }
    _pageChangeController.add(newPage);
  }

  /// Notify observers of errors
  void _notifyError(String message) {
    for (final observer in _observers) {
      observer.onError(message);
    }
    _errorController.add(message);
  }

  /// Notify observers of page added
  void _notifyPageAdded(PageType pageType) {
    for (final observer in _observers) {
      observer.onPageAdded(pageType);
    }
    _pageAddedController.add(pageType);
  }

  /// Notify observers of page removed
  void _notifyPageRemoved(PageType pageType) {
    for (final observer in _observers) {
      observer.onPageRemoved(pageType);
    }
    _pageRemovedController.add(pageType);
  }
}
