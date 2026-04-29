import 'package:flutter/material.dart';
import 'package:onis_viewer/api/core/ov_api_core.dart';
import 'package:onis_viewer/core/constants.dart';
import 'package:onis_viewer/core/layout/view_layout.dart';
import 'package:onis_viewer/core/layout/view_layout_node.dart';
import 'package:onis_viewer/core/models/entities/patient.dart' as entities;
import 'package:onis_viewer/core/monitor/page_widget.dart';
import 'package:onis_viewer/plugins/viewer/history_bar/viewer_history_bar.dart';
import 'package:onis_viewer/plugins/viewer/info_box/viewer_info_box.dart';
import 'package:onis_viewer/plugins/viewer/public/viewer_api.dart';
import 'package:onis_viewer/plugins/viewer/toolbar/viewer_toolbar.dart';
import 'package:onis_viewer/plugins/viewer/view_area/view_area.dart';

class ViewerPageWidget extends OsPageWidget {
  ViewerPageWidget({
    super.key,
    required super.page,
  });

  @override
  OsPageWidgetState<ViewerPageWidget> createPageState() =>
      _ViewerPageWidgetState();
}

class _ViewerPageWidgetState extends OsPageWidgetState<ViewerPageWidget> {
  ViewerApi? _viewerApi;

  @override
  Future<void> initializePage() async {
    _viewerApi = OVApi().plugins.getPublicApi<ViewerApi>('onis_viewer_plugin');
  }

  @override
  Future<void> disposePage() async {}

  @override
  Widget buildPageContent() {
    final layout = _viewerApi?.layout;
    return AnimatedBuilder(
      animation: layout as Listenable,
      builder: (context, child) {
        return _buildContent(layout!);
      },
    );
  }

  @override
  Widget? buildPageHeader() {
    // No header - toolbar is part of the content layout
    return ViewerToolbar(
      //controller: _controller,
      height: 50.0,
    );
  }

  /// Build the main content area
  Widget _buildContent(ViewLayout layout) {
    return Container(
      color: OnisViewerConstants.backgroundColor,
      child: Column(
        children: [
          // Toolbar at the top - fixed height, full width
          /*ViewerToolbar(
            controller: _controller,
            height: 50.0,
          ),*/
          // Main content area with history bar, image viewer, and info box
          Expanded(
            child: Row(
              children: [
                // History bar on the left - fixed width, remaining height
                ViewerHistoryBar(
                  width: 200.0,
                  historyItems: _getHistoryItems(),
                ),

                // Image viewer in the center - takes remaining space
                Expanded(
                  child: ViewArea(
                    layout: layout,
                    onSeriesDropped: _onSeriesDroppedOnView,
                  ),
                ),

                // Info box on the right - resizable, remaining height
                ViewerInfoBox(
                  initialWidth: 300.0,
                  minWidth: 200.0,
                  maxWidth: 600.0,
                  infoItems: {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Called when a series is dropped from the history bar onto a view cell
  void _onSeriesDroppedOnView(
      ViewLayoutNode layoutNode, entities.Series series) {
    final modality = series.databaseInfo?.modality ?? '';
    final desc = series.databaseInfo?.description ?? '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Series dropped: ${modality.isNotEmpty ? modality : "—"} '
          '${desc.isNotEmpty ? "($desc)" : ""}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Get history items for the history bar
  List<String> _getHistoryItems() {
    return [];
  }

  /// Build the image viewer
  /*Widget _buildImageViewer() {
    return SizedBox();
    /*return Center(
      child: InteractiveViewer(
        minScale: 0.1,
        maxScale: 5.0,
        onInteractionEnd: _controller.onZoomChanged,
        child: Image.memory(
          _controller.currentImage!.data,
          fit: BoxFit.contain,
        ),
      ),
    );*/
  }
  */

  @override
  String getPageStatus() {
    return 'Viewer';
  }
}
