import 'dart:core';

import 'package:flutter/material.dart';
import 'package:onis_viewer/api/ov_api.dart';

import '../../../core/database_source.dart';
import 'credentials/credential_store.dart';
import 'ui/site_server_connection_panel.dart';
import 'ui/site_server_login_panel.dart';

/// Represents different types of child sources that can be created under a site source
enum SiteChildSourceType {
  partition,
  album,
  dicomPacs,
  dicomFolder,
  partitionFolder
}

/// A child source under a site source (partition, album, or DICOM PACS)
class SiteChildSource extends DatabaseSource {
  final SiteChildSourceType type;
  final String parentSiteUid;

  SiteChildSource({
    required super.uid,
    required super.name,
    required this.type,
    required this.parentSiteUid,
    super.metadata,
  }) {
    // Child sources are active by default since they represent available data
    isActive = true;
  }

  /// Get the type as a display string
  String get typeDisplayName {
    switch (type) {
      case SiteChildSourceType.partition:
        return 'Partition';
      case SiteChildSourceType.album:
        return 'Album';
      case SiteChildSourceType.dicomPacs:
        return 'DICOM PACS';
      case SiteChildSourceType.dicomFolder:
        return 'DICOM Folder';
      case SiteChildSourceType.partitionFolder:
        return 'Partition Folder';
    }
  }

  /// Get an icon for this source type
  IconData get typeIcon {
    switch (type) {
      case SiteChildSourceType.partition:
        return Icons.folder;
      case SiteChildSourceType.album:
        return Icons.photo_library;
      case SiteChildSourceType.dicomPacs:
        return Icons.medical_services;
      case SiteChildSourceType.dicomFolder:
        return Icons.folder_open;
      case SiteChildSourceType.partitionFolder:
        return Icons.folder_special;
    }
  }

  @override
  bool get canSearch => isActive;

  @override
  void search() {
    debugPrint('SiteChildSource.search() called for $typeDisplayName: $name');
    // Trigger search in the database controller
    final api = OVApi();
    final dbApi = api.plugins.getPublicApi('onis_database_plugin');
    if (dbApi != null) {
      // This will trigger the search functionality in the database page
      debugPrint('Triggering search for child source: $name');
    }
  }
}

class SiteSource extends DatabaseSource {
  /// Public constructor for a site source (without parent)
  /// Parent relationships should be managed by DatabaseSourceManager
  SiteSource({required super.uid, required super.name, super.metadata})
      : super();

  // Track last used credentials and pending login per source
  String? _lastUsername;
  String? _lastPassword;
  bool _lastRemember = false;
  bool _isLoggingIn = false;
  bool _isDisconnecting = false;

  /// Get the current logged-in username (if any)
  @override
  String? get currentUsername => _lastUsername;

  /// Get whether the source is currently disconnecting
  @override
  bool get isDisconnecting => _isDisconnecting;

  /// Get whether this source is a root site source (always true for SiteSource)
  bool get isRootSite => true;

  /// Get child sources of a specific type
  List<SiteChildSource> getChildSourcesByType(SiteChildSourceType type) {
    return subSources
        .whereType<SiteChildSource>()
        .where((source) => source.type == type)
        .toList();
  }

  /// Get all partitions
  List<SiteChildSource> get partitions =>
      getChildSourcesByType(SiteChildSourceType.partition);

  /// Get all albums
  List<SiteChildSource> get albums =>
      getChildSourcesByType(SiteChildSourceType.album);

  /// Get all DICOM PACS sources
  List<SiteChildSource> get dicomPacsSources =>
      getChildSourcesByType(SiteChildSourceType.dicomPacs);

  /// Disconnect from the source
  @override
  Future<void> disconnect() async {
    _isDisconnecting = true;
    notifyListeners();

    // Simulate slow server response for disconnect
    await Future.delayed(const Duration(seconds: 10));

    // Remove all child sources that were created during login
    final api = OVApi();
    final manager = api.sources;

    // Get all child sources of this site source
    final childSources = manager.allSources
        .where((source) =>
            source is SiteChildSource && (source).parentSiteUid == uid)
        .toList();

    // Remove each child source
    for (final childSource in childSources) {
      manager.removeSource(childSource);
    }

    // Mark source as disconnected
    isActive = false;
    _lastUsername = null;
    _lastPassword = null;
    _lastRemember = false;
    _isLoggingIn = false;
    _isDisconnecting = false;

    debugPrint(
        'Disconnected from site: $name (removed ${childSources.length} child sources)');

    notifyListeners();
  }

  /// Mock login: optionally store credentials, wait 10 seconds, then mark active
  Future<void> login({
    required String username,
    required String password,
    required bool remember,
  }) async {
    _lastUsername = username;
    _lastPassword = password;
    _lastRemember = remember;
    _isLoggingIn = true;
    notifyListeners();

    // Simulate slow server response for login
    await Future.delayed(const Duration(seconds: 1));

    // Store or clear credentials based on remember flag
    if (remember) {
      await SiteServerCredentialStore.save(
        uid,
        username: username,
        password: password,
        remember: true,
      );
    } else {
      await SiteServerCredentialStore.clear(uid);
    }

    // Mark source as active
    isActive = true;

    // Create child sources after successful authentication
    _createChildSources();

    // Auto-expand the site source node in the source tree
    final api = OVApi();
    final dbApi = api.plugins.getPublicApi('onis_database_plugin');
    if (dbApi != null) {
      dbApi.expandSourceNode(uid, expand: true, expandChildren: true);
    }

    // Reset logging-in flag
    _isLoggingIn = false;
    notifyListeners();
  }

  @override
  Widget? buildLoginPanel(BuildContext context) {
    // Only show login panel if not authenticated and no child sources exist
    if (isActive || subSources.isNotEmpty) {
      return null;
    }

    return KeyedSubtree(
      key: ValueKey<String>('login-$uid'),
      child: FutureBuilder<SiteServerCredentials?>(
        future: SiteServerCredentialStore.load(uid),
        builder: (context, snapshot) {
          final saved = snapshot.data;
          final initialUsername = _isLoggingIn
              ? (_lastUsername ?? saved?.username)
              : (saved?.username);
          final initialPassword = _isLoggingIn
              ? (_lastPassword ?? saved?.password)
              : (saved?.password);
          final initialRemember =
              _isLoggingIn ? _lastRemember : (saved?.remember ?? false);
          return SiteServerLoginPanel(
            initialUsername: initialUsername,
            initialPassword: initialPassword,
            initialRemember: initialRemember,
            initialSubmitting: _isLoggingIn,
            instanceName: name,
            onSubmitAsync: (username, password, remember) async {
              await login(
                username: username,
                password: password,
                remember: remember,
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget? buildConnectionPanel(BuildContext context) {
    // Metadata keys are optional; adjust as needed
    final url = metadata['url'] as String?;
    final instanceName = name;
    return SiteServerConnectionPanel(
      initialUrl: url,
      initialInstanceName: instanceName,
      onSave: () {},
    );
  }

  @override
  bool get canSearch => isActive;

  @override
  void search() {
    // Site source specific open/search implementation
    debugPrint('SiteSource.search() called for source: $name');
    // TODO: Implement site-specific search functionality
    // This could open a search dialog, navigate to a search page, etc.
  }

  void _createChildSources() {
    // Create partition source as a child of this site source

    final partitionsFolder = SiteChildSource(
      uid: '${uid}_partitions',
      name: 'Partitions',
      type: SiteChildSourceType.partitionFolder,
      parentSiteUid: uid,
      metadata: {
        'type': 'partition_list',
        'parent_site': uid,
      },
    );

    OVApi().sources.registerSource(partitionsFolder, parentUid: uid);

    final partition1 = SiteChildSource(
      uid: '${uid}_partition1',
      name: 'Partition 1',
      type: SiteChildSourceType.partition,
      parentSiteUid: uid,
      metadata: {
        'type': 'partition',
        'parent_site': uid,
        'description': 'Main clinical data partition',
        'size': '2.5 TB',
      },
    );
    OVApi().sources.registerSource(partition1, parentUid: partitionsFolder.uid);

    final partition2 = SiteChildSource(
      uid: '${uid}_partition2',
      name: 'Partition 2',
      type: SiteChildSourceType.partition,
      parentSiteUid: uid,
      metadata: {
        'type': 'partition',
        'parent_site': uid,
        'description': 'Research and development data',
        'size': '1.8 TB',
      },
    );
    OVApi().sources.registerSource(partition2, parentUid: partitionsFolder.uid);

    debugPrint('Created child sources for site: $name');
    debugPrint('- Partitions folder: ${partitionsFolder.name}');
    debugPrint('- Partitions: ${partition1.name}, ${partition2.name}');
  }
}
