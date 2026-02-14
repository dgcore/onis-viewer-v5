import 'package:flutter/material.dart';
import 'package:onis_viewer/api/core/ov_api_core.dart';
import 'package:onis_viewer/plugins/viewer/public/layout_controller_interface.dart';
import 'package:onis_viewer/plugins/viewer/public/viewer_api.dart';
import 'package:onis_viewer/plugins/viewer/toolbar/viewer_toolbar.dart';
import 'package:onis_viewer/plugins/viewer/view_area/view_area.dart';

import '../../../core/constants.dart';
import '../../../pages/base/base_page.dart';
import '../history_bar/viewer_history_bar.dart';
import '../info_box/viewer_info_box.dart';
import '../viewer_plugin.dart';

/// Medical image viewer page
class ViewerPage extends BasePage {
  const ViewerPage({
    super.key,
    super.parameters,
  }) : super(
          pageType: viewerPageType,
        );

  @override
  BasePageState createPageState() => _ViewerPageState();
}

class _ViewerPageState extends BasePageState<ViewerPage> {
  ViewerApi? _viewerApi;
  //late ViewerController _controller;

  @override
  Future<void> initializePage() async {
    _viewerApi = OVApi().plugins.getPublicApi<ViewerApi>('onis_viewer_plugin');
  }

  @override
  Future<void> disposePage() async {}

  @override
  Widget buildPageContent() {
    final layoutController = _viewerApi?.layoutController;
    return AnimatedBuilder(
      animation: layoutController as Listenable,
      builder: (context, child) {
        return _buildContent(layoutController!);
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
  Widget _buildContent(ILayoutController layoutController) {
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
                  width: 250.0,
                  historyItems: _getHistoryItems(),
                ),

                // Image viewer in the center - takes remaining space
                Expanded(child: ViewArea(layoutController: layoutController)),

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

  /// Get history items for the history bar
  List<String> _getHistoryItems() {
    // TODO: Implement history tracking
    // For now, return empty list or sample data
    return [];
  }

  /// Build the image viewer
  Widget _buildImageViewer() {
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

  /// Build widget when no image is loaded
  /*Widget _buildNoImageWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            size: 64,
            color: OnisViewerConstants.textSecondaryColor,
          ),
          const SizedBox(height: OnisViewerConstants.marginMedium),
          Text(
            'No Image Loaded',
            style: const TextStyle(
              color: OnisViewerConstants.textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: OnisViewerConstants.marginSmall),
          Text(
            'Open an image to start viewing',
            style: const TextStyle(
              color: OnisViewerConstants.textSecondaryColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: OnisViewerConstants.marginLarge),
          ElevatedButton.icon(
            onPressed: _controller.openImage,
            icon: const Icon(Icons.folder_open),
            label: const Text('Open Image'),
          ),
        ],
      ),
    );
  }*/

  /*@override
  List<Widget> buildToolbarItems() {
    return [
      // Viewer-specific toolbar items
      IconButton(
        onPressed: _controller.toggleFullscreen,
        icon: const Icon(Icons.fullscreen),
        tooltip: 'Toggle Fullscreen',
      ),
    ];
  }

  @override
  List<Widget> buildFooterItems() {
    return [
      // Viewer-specific footer items
      if (_controller.currentImage != null)
        Text(
          'Image: ${_controller.currentImage!.name}',
          style: const TextStyle(
            fontSize: 12,
            color: OnisViewerConstants.textSecondaryColor,
          ),
        ),
    ];
  }*/

  @override
  String getPageStatus() {
    /*return _controller.currentImage != null
        ? 'Viewing: ${_controller.currentImage!.name}'
        : 'No image loaded';*/
    return 'Viewer';
  }
}
