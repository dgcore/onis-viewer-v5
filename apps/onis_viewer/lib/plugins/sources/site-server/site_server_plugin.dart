import 'package:flutter/material.dart';
import 'package:onis_viewer/api/core/ov_api_core.dart';
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

    // Register two site server sources
    final api = OVApi();

    final siteServerSource = SiteSource(
        uid: 'site_server_1',
        name: 'Site Server 1',
        metadata: {'type': 'site_server', 'url': 'http://localhost:8080'});
    api.sources.registerSource(siteServerSource);

    final partition = SiteSource(
        uid: 'partition_1',
        name: 'Partition 1',
        metadata: {'type': 'site_server', 'url': 'http://localhost:8080'});
    api.sources.registerSource(partition, parentUid: siteServerSource.uid);

    final siteServerSource2 = SiteSource(
        uid: 'site_server_2',
        name: 'Site Server 2',
        metadata: {'type': 'site_server', 'url': 'http://localhost:8080'});
    api.sources.registerSource(siteServerSource2);

    debugPrint('Registered 2 site server sources');
  }

  @override
  Future<void> dispose() async {
    // Future: cleanup resources, timers, or subscriptions here
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
