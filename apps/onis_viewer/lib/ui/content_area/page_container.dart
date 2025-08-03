import 'package:flutter/material.dart';

import '../../api/ov_api.dart';
import '../../core/page_factory.dart';
import '../../core/page_type.dart';
import '../common/unknown_page_widget.dart';

/// Container for displaying pages based on page type
class PageContainer extends StatefulWidget {
  final PageType pageType;
  final OVApi api;

  const PageContainer({
    super.key,
    required this.pageType,
    required this.api,
  });

  @override
  State<PageContainer> createState() => _PageContainerState();
}

class _PageContainerState extends State<PageContainer> {
  Widget? _currentPageWidget;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  @override
  void didUpdateWidget(PageContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageType != widget.pageType) {
      _loadPage();
    }
  }

  /// Load the page widget for the current page type
  void _loadPage() {
    // Use the PageFactory to create the page
    final pageWidget = PageFactory().createPage(widget.pageType);

    if (pageWidget != null) {
      setState(() {
        _currentPageWidget = pageWidget;
      });
    } else {
      setState(() {
        _currentPageWidget = UnknownPageWidget(pageType: widget.pageType);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPageWidget == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return _currentPageWidget!;
  }
}
