import 'package:flutter/material.dart';

import '../plugins/database/page/database_page.dart';
import '../plugins/viewer/page/viewer_page.dart';
import 'page_type.dart';

/// Factory for creating page widgets from page types
class PageFactory {
  static final PageFactory _instance = PageFactory._internal();
  factory PageFactory() => _instance;
  PageFactory._internal();

  /// Create a page widget for the given page type
  Widget? createPage(PageType pageType) {
    // First, try to use the page creator from the PageType
    if (pageType.pageCreator != null) {
      try {
        return pageType.pageCreator!(pageType);
      } catch (e) {
        debugPrint(
            'Failed to create page using pageCreator for ${pageType.id}: $e');
      }
    }

    // Fallback to built-in page creation if no creator is provided
    return _createBuiltinPage(pageType);
  }

  /// Create built-in pages as fallback
  Widget? _createBuiltinPage(PageType pageType) {
    switch (pageType.id) {
      case 'database':
        return const DatabasePage();
      case 'viewer':
        return const ViewerPage();
      default:
        debugPrint('No built-in page creator for: ${pageType.id}');
        return null;
    }
  }

  /// Create a page widget by page type ID
  Widget? createPageById(String pageTypeId) {
    final pageType = PageType.fromId(pageTypeId);
    if (pageType != null) {
      return createPage(pageType);
    }
    debugPrint('Page type not found: $pageTypeId');
    return null;
  }

  /// Check if a page type has a creator
  bool hasPageCreator(PageType pageType) {
    return pageType.pageCreator != null || _hasBuiltinCreator(pageType.id);
  }

  /// Check if a page type ID has a built-in creator
  bool hasPageCreatorById(String pageTypeId) {
    return _hasBuiltinCreator(pageTypeId);
  }

  /// Check if a page type ID has a built-in creator
  bool _hasBuiltinCreator(String pageTypeId) {
    switch (pageTypeId) {
      case 'database':
      case 'viewer':
        return true;
      default:
        return false;
    }
  }

  /// Get all page type IDs that have creators
  List<String> get availablePageTypeIds {
    final ids = <String>[];

    // Add registered page types with creators
    for (final pageType in PageType.registeredTypes) {
      if (hasPageCreator(pageType)) {
        ids.add(pageType.id);
      }
    }

    return ids;
  }
}
