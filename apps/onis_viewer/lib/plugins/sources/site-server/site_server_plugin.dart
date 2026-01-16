import 'package:flutter/material.dart';
import 'package:onis_viewer/api/core/ov_api_core.dart';
import 'package:onis_viewer/plugins/database/public/database_api.dart';
import 'package:onis_viewer/plugins/sources/site-server/site_source.dart';

import '../../../core/plugin_interface.dart';

/// Site Server Sources plugin
/// This plugin will provide site-server based sources management.
class SiteServerPlugin implements OnisViewerPlugin {
  @override
  String get id => 'onis_sources_site_server';

  @override
  String get name => 'Site Server Sources';

  @override
  String get version => '0.1.0';

  @override
  String get description =>
      'Provides site-server based database sources and synchronization.';

  @override
  String get author => 'ONIS Team';

  @override
  IconData? get icon => Icons.dns_outlined;

  @override
  Color? get color => Colors.orange;

  @override
  Future<void> initialize() async {
    // Future: register source types, services, and any background tasks here
    debugPrint('SiteServerPlugin initialized');

    final dbApi =
        OVApi().plugins.getPublicApi<DatabaseApi>('onis_database_plugin');
    if (dbApi != null) {
      dbApi.sourceController.sources.registerSource(SiteSource(
        uid: 'site_server_1',
        name: 'Site Server 1',
        metadata: {'type': 'site_server', 'url': 'http://localhost:8080'},
      ));
      dbApi.sourceController.sources.registerSource(SiteSource(
        uid: 'site_server_2',
        name: 'Site Server 2',
        metadata: {'type': 'site_server', 'url': 'http://localhost:8080'},
      ));
      debugPrint(
          'Registered 2 site server sources (child sources will be created after authentication)');
    }
  }

  @override
  Future<void> dispose() async {
    // Future: cleanup resources, timers, or subscriptions here
    debugPrint('SiteServerPlugin disposed');
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
  Object? get publicApi => null;
}
