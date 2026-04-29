import 'package:flutter/material.dart';
import 'package:onis_viewer/api/core/ov_api_core.dart';
import 'package:onis_viewer/api/managers/page_type_manager.dart';
import 'package:onis_viewer/core/layout/view_layout.dart';
import 'package:onis_viewer/core/monitor/page_type.dart';
import 'package:onis_viewer/core/toolbar/toolbar_item.dart';
import 'package:onis_viewer/plugins/viewer/public/viewer_api.dart';
import 'package:onis_viewer/plugins/viewer/toolbar_items/layout_toolbar_item.dart';
import 'package:onis_viewer/plugins/viewer/toolbar_items/tools_toolbar_item.dart';

import '../../core/plugin_interface.dart';
import 'page/viewer_page.dart';

/// Viewer page type constant
/*const PageType viewerPageType = PageType(
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
}*/

class _ViewerApiImpl implements ViewerApi {
  //final _layoutController = LayoutController();
  final _layout = ViewLayout();
  final _toolbar = OsToolbar('layout_toolbar');

  @override
  ViewLayout get layout => _layout;

  @override
  OsToolbar get toolbar => _toolbar;

  //@override
  //ILayoutController get layoutController => _layoutController;

  Future<void> initialize() async {
    _toolbar.addItem(OsLayoutToolbarItem('layout_toolbar_item', 'Layout'));
    _toolbar.addItem(OsToolsToolbarItem('tools_toolbar_item', 'Tools'));
    _layout.setTiling(1, 1);
  }

  Future<void> dispose() async {
    //_layoutController.dispose();
  }
}

/// Built-in viewer plugin
class ViewerPlugin implements OnisViewerPlugin {
  _ViewerApiImpl? _api;
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
    // Register the Database page type:
    OsPageType viewerPageType = OsViewerPageType();
    OsPageTypeManager pageTypeManager = OVApi().pageTypes;
    pageTypeManager.registerItem(viewerPageType, true);

    // Create public API implementation
    _api = _ViewerApiImpl();
    await _api!.initialize();

    /*OsPageType viewerPageType = OsPageType(id: 'viewer', name: 'Viewer');
    OsPageTypeManager pageTypeManager = OVApi().pageTypes;
    pageTypeManager.registerItem(viewerPageType, true);*/

    // Register the page type (includes page creator)
    //PageType.register(viewerPageType);
  }

  @override
  Future<void> dispose() async {
    // Unregister the page type (includes page creator)
    //PageType.unregister(viewerPageType.id);
    OsPageTypeManager pageTypeManager = OVApi().pageTypes;
    OsPageType? viewerPageType = pageTypeManager.find('viewer');
    if (viewerPageType != null) {
      pageTypeManager.registerItem(viewerPageType, false);
    }
    await _api!.dispose();
    _api = null;
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

  @override
  Object? get publicApi => _api;
}
