import 'package:flutter/material.dart';
import 'package:onis_viewer/core/constants.dart';
import 'package:onis_viewer/core/page_type.dart';
import 'package:onis_viewer/u i/status_bar/status_bar.dart';
import 'package:onis_viewer/ui/content_area/content_area.dart';

class OsMonitorWidget extends StatefulWidget {
  //late final WeakReference<OsMonitorWnd>? wMonitorWnd;
  const OsMonitorWidget(
      {super.key /*, required OsMonitorWnd monitorWnd*/}) /*: wMonitorWnd = WeakReference(monitorWnd)*/;

  @override
  State<OsMonitorWidget> createState() => OsMonitorWidgetState();
}

class OsMonitorWidgetState extends State<OsMonitorWidget> {
  final List<PageType> _availablePages = [];
  PageType? _currentPage;
  final Function(PageType) _onPageSelected = (pageType) {};

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildMainContent(),
        // Quit dialog overlay
        //if (_showQuitDialog) _buildModalQuitDialog(),
      ],
    );
  }

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canShowStatusBar =
            constraints.maxHeight > OnisViewerConstants.statusBarHeight;
        return Column(
          children: [
            // Main content area
            const Expanded(
              child: ContentArea(),
            ),
            // Hide status bar in very small layouts to avoid overflow.
            if (canShowStatusBar)
              StatusBar(
                availablePages: _availablePages,
                currentPage: _currentPage,
                onPageSelected: _onPageSelected,
                additionalWidgets: _buildStatusBarWidgets(),
              ),
          ],
        );
      },
    );
    /*return CustomWindowFrame(
      title: OnisViewerConstants.appName,
      child: Column(
        children: [
          // Main content area
          Expanded(
            child: ContentArea(),
          ),
          // Status bar with tabs
          StatusBar(
            availablePages: _availablePages,
            currentPage: _currentPage,
            onPageSelected: _onPageSelected,
            additionalWidgets: _buildStatusBarWidgets(),
          ),
        ],
      ),
    );*/
  }

  List<Widget> _buildStatusBarWidgets() {
    return [];
  }
}
