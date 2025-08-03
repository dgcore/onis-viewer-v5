import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../pages/base/base_page.dart';
import '../viewer_plugin.dart';
import 'viewer_controller.dart';

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
  late ViewerController _controller;

  @override
  Future<void> initializePage() async {
    _controller = ViewerController();
    await _controller.initialize();
  }

  @override
  Future<void> disposePage() async {
    await _controller.dispose();
  }

  @override
  Widget buildPageContent() {
    return _buildContent();
  }

  @override
  Widget? buildPageHeader() {
    // Return the viewer toolbar as the custom page header
    return _buildToolbar();
  }

  /// Build the viewer toolbar
  Widget _buildToolbar() {
    return Container(
      height: 50,
      color: OnisViewerConstants.surfaceColor,
      padding: const EdgeInsets.symmetric(
        horizontal: OnisViewerConstants.paddingMedium,
      ),
      child: Row(
        children: [
          // Open image button
          ElevatedButton.icon(
            onPressed: _controller.openImage,
            icon: const Icon(Icons.folder_open),
            label: const Text('Open Image'),
          ),
          const SizedBox(width: OnisViewerConstants.marginMedium),

          // Save button
          ElevatedButton.icon(
            onPressed: _controller.saveImage,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
          const SizedBox(width: OnisViewerConstants.marginMedium),

          // Zoom controls
          IconButton(
            onPressed: _controller.zoomIn,
            icon: const Icon(Icons.zoom_in),
            tooltip: 'Zoom In',
          ),
          IconButton(
            onPressed: _controller.zoomOut,
            icon: const Icon(Icons.zoom_out),
            tooltip: 'Zoom Out',
          ),
          IconButton(
            onPressed: _controller.resetZoom,
            icon: const Icon(Icons.zoom_out_map),
            tooltip: 'Reset Zoom',
          ),

          const Spacer(),

          // Image info
          if (_controller.currentImage != null) ...[
            Text(
              '${_controller.currentImage!.width} × ${_controller.currentImage!.height}',
              style: const TextStyle(
                color: OnisViewerConstants.textSecondaryColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: OnisViewerConstants.marginMedium),
            Text(
              'Zoom: ${(_controller.zoomLevel * 100).toInt()}%',
              style: const TextStyle(
                color: OnisViewerConstants.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build the main content area
  Widget _buildContent() {
    return Container(
      color: OnisViewerConstants.backgroundColor,
      child: _controller.currentImage != null
          ? _buildImageViewer()
          : _buildNoImageWidget(),
    );
  }

  /// Build the image viewer
  Widget _buildImageViewer() {
    return Center(
      child: InteractiveViewer(
        minScale: 0.1,
        maxScale: 5.0,
        onInteractionEnd: _controller.onZoomChanged,
        child: Image.memory(
          _controller.currentImage!.data,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// Build widget when no image is loaded
  Widget _buildNoImageWidget() {
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
  }

  @override
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
  }

  @override
  String getPageStatus() {
    return _controller.currentImage != null
        ? 'Viewing: ${_controller.currentImage!.name}'
        : 'No image loaded';
  }
}
