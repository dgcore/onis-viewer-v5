import 'package:flutter/material.dart';

import '../../core/page_type.dart';
import '../../core/plugin_interface.dart';
import 'page/viewer_page.dart';

/// Viewer page type constant
const PageType viewerPageType = PageType(
  id: 'viewer',
  name: 'Viewer',
  description: 'View and analyze medical images',
  icon: Icons.visibility,
  color: Colors.green,
  pageCreator: _createViewerPage,
);

/// Create viewer page widget
Widget _createViewerPage(PageType pageType) {
  return const ViewerPage();
}

/// Built-in viewer plugin
class ViewerPlugin implements OnisViewerPlugin {
  @override
  String get id => 'onis_viewer_plugin';

  @override
  String get name => 'Viewer Plugin';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Provides medical image viewing functionality';

  @override
  String get author => 'ONIS Team';

  @override
  IconData? get icon => Icons.visibility;

  @override
  Color? get color => Colors.green;

  @override
  Future<void> initialize() async {
    // Register the page type (includes page creator)
    PageType.register(viewerPageType);
  }

  @override
  Future<void> dispose() async {
    // Unregister the page type (includes page creator)
    PageType.unregister(viewerPageType.id);
  }

  @override
  bool get isValid => true;

  @override
  Map<String, dynamic> get metadata => {
        'id': id,
        'name': name,
        'version': version,
        'description': description,
        'author': author,
      };
}
