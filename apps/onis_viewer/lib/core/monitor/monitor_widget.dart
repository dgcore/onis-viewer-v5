import 'package:flutter/material.dart';
import 'package:onis_viewer/core/constants.dart';
import 'package:onis_viewer/core/monitor/monitor_wnd.dart';
import 'package:onis_viewer/core/monitor/page.dart';
import 'package:onis_viewer/ui/status_bar/status_bar.dart';

class OsMonitorWidget extends StatefulWidget {
  final OsMonitorWnd monitorWnd;
  const OsMonitorWidget({super.key, required this.monitorWnd});

  @override
  State<OsMonitorWidget> createState() => OsMonitorWidgetState();
}

class OsMonitorWidgetState extends State<OsMonitorWidget> {
  //final List<OsPageType> _availablePages = [];
  //OsPageType? _currentPage;
  final Map<OsPage, Widget> _pageWidgetCache = {};

  void _onPageSelected(OsPage page) {
    widget.monitorWnd.selectPage(page.getType()?.getId() ?? '', true);
  }

  @override
  void initState() {
    super.initState();
    widget.monitorWnd.addListener(_onMonitorWndChanged);
  }

  @override
  void didUpdateWidget(covariant OsMonitorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.monitorWnd, widget.monitorWnd)) {
      oldWidget.monitorWnd.removeListener(_onMonitorWndChanged);
      widget.monitorWnd.addListener(_onMonitorWndChanged);
      _pageWidgetCache.clear();
    }
  }

  @override
  void dispose() {
    widget.monitorWnd.removeListener(_onMonitorWndChanged);
    _pageWidgetCache.clear();
    /*if (_messageSubscription != null) {
      OVApi().messages.unsubscribe(_messageSubscription!);
      _messageSubscription = null;
    }*/
    super.dispose();
  }

  void _onMonitorWndChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /*void onReceivedMessage(int id, dynamic data) {
    debugPrint('OsMonitorWidgetState: onReceivedMessage, id=$id, data=$data');
  }*/

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
    final pages = widget.monitorWnd.pages;
    final currentPage = widget.monitorWnd.selectedPage;
    // Keep page widgets alive across tab switches (Database should not dispose
    // when hidden). Remove stale cache entries if pages disappear.
    _pageWidgetCache.removeWhere((page, _) => !pages.contains(page));
    final children = pages.map((page) {
      return _pageWidgetCache.putIfAbsent(
        page,
        () =>
            page.getWnd()?.createPageWidget() ?? Container(color: Colors.black),
      );
    }).toList();

    Widget mainContent;
    if (children.isEmpty) {
      mainContent = Container(color: Colors.black);
    } else {
      final currentIndex = currentPage != null ? pages.indexOf(currentPage) : 0;
      final safeIndex = currentIndex >= 0 ? currentIndex : 0;
      mainContent = IndexedStack(
        index: safeIndex,
        children: children,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final canShowStatusBar =
            constraints.maxHeight > OnisViewerConstants.statusBarHeight;
        return Column(
          children: [
            // Main content area
            Expanded(
              child: mainContent,
            ),
            // Hide status bar in very small layouts to avoid overflow.
            if (canShowStatusBar)
              StatusBar(
                availablePages: pages,
                currentPage: currentPage,
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
