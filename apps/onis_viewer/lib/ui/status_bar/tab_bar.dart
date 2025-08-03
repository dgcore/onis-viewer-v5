import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/page_type.dart';
import 'tab_button.dart';

/// Horizontal tab bar containing tab buttons
class OnisTabBar extends StatelessWidget {
  final List<PageType> availablePages;
  final PageType? currentPage;
  final Function(PageType) onPageSelected;

  const OnisTabBar({
    super.key,
    required this.availablePages,
    required this.currentPage,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: OnisViewerConstants.tabButtonHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: availablePages.map((pageType) {
          final isSelected = currentPage == pageType;
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: OnisViewerConstants.marginSmall,
            ),
            child: TabButton(
              pageType: pageType,
              isSelected: isSelected,
              onPressed: () => onPageSelected(pageType),
            ),
          );
        }).toList(),
      ),
    );
  }
}
