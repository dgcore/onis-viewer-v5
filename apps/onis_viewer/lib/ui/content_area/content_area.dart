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

  @override
  void initState() {
    super.initState();
    _api.pages.addObserver(this);
    _currentPage = _api.pages.currentPage;
  }

  @override
  void dispose() {
    _api.pages.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: OnisViewerConstants.backgroundColor,
      child: _currentPage != null
          ? PageContainer(pageType: _currentPage!, api: _api)
          : _buildNoPageWidget(),
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
      });
    }
  }

  @override
  void onPageAdded(PageType pageType) {
    // Handle page added event
    debugPrint('Page added in ContentArea: ${pageType.name}');
  }

  @override
  void onPageRemoved(PageType pageType) {
    // Handle page removed event
    debugPrint('Page removed in ContentArea: ${pageType.name}');
  }

  @override
  void onError(String message) {
    // Handle error event
    debugPrint('Error in ContentArea: $message');
  }
}
