import 'package:flutter/material.dart';
import 'package:onis_viewer/core/monitor/page.dart';
import 'package:onis_viewer/core/theme/app_theme.dart';

import '../../core/constants.dart';
import 'tab_bar.dart';

/// Status bar widget that contains tab buttons at the bottom
class StatusBar extends StatelessWidget {
  final List<OsPage> availablePages;
  final OsPage? currentPage;
  final Function(OsPage) onPageSelected;
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
    final appTheme = context.appTheme;
    return Container(
      height: OnisViewerConstants.statusBarHeight,
      decoration: BoxDecoration(
        color: appTheme.statusBarBg,
        border: Border(
          top: BorderSide(
            color: appTheme.panelBorder,
            width: 1,
          ),
        ),
      ),
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
          if (additionalWidgets != null && additionalWidgets!.isNotEmpty)
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: OnisViewerConstants.marginMedium),
                      ...additionalWidgets!,
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
