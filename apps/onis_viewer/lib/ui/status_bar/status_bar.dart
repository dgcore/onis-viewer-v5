import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/page_type.dart';
import 'tab_bar.dart';

/// Status bar widget that contains tab buttons at the bottom
class StatusBar extends StatelessWidget {
  final List<PageType> availablePages;
  final PageType? currentPage;
  final Function(PageType) onPageSelected;
  final List<Widget>? additionalWidgets;

  const StatusBar({
    super.key,
    required this.availablePages,
    required this.currentPage,
    required this.onPageSelected,
    this.additionalWidgets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: OnisViewerConstants.statusBarHeight,
      color: OnisViewerConstants.statusBarColor,
      child: Row(
        children: [
          // Tab bar (centered)
          Expanded(
            child: Center(
              child: OnisTabBar(
                availablePages: availablePages,
                currentPage: currentPage,
                onPageSelected: onPageSelected,
              ),
            ),
          ),

          // Additional widgets (right side)
          if (additionalWidgets != null) ...[
            const SizedBox(width: OnisViewerConstants.marginMedium),
            ...additionalWidgets!,
          ],

          const SizedBox(width: OnisViewerConstants.marginMedium),
        ],
      ),
    );
  }
}
