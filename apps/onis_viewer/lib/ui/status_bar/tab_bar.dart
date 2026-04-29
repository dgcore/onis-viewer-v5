import 'package:flutter/material.dart';
import 'package:onis_viewer/core/monitor/page.dart';

import '../../core/constants.dart';
import 'tab_button.dart';

/// Horizontal tab bar containing tab buttons
class OnisTabBar extends StatelessWidget {
  final List<OsPage> availablePages;
  final OsPage? currentPage;
  final Function(OsPage) onPageSelected;

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
        mainAxisAlignment: MainAxisAlignment.center,
        children: availablePages.map((page) {
          final isSelected = currentPage == page;
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: OnisViewerConstants.marginSmall,
            ),
            child: TabButton(
              page: page,
              isSelected: isSelected,
              onPressed: () => onPageSelected(page),
            ),
          );
        }).toList(),
      ),
    );
  }
}
