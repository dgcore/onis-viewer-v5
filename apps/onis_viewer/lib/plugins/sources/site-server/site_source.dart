import 'dart:core';

import 'package:flutter/material.dart';
import 'package:onis_viewer/api/ov_api.dart';

import '../../../api/request/async_request.dart';
import '../../../core/database_source.dart';
import 'credentials/credential_store.dart';
import 'request/site_async_request.dart';
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
  WeakReference<SiteSource>? _parentSiteRef;

  SiteChildSource({
    required super.uid,
    required super.name,
    required this.type,
    super.metadata,
  }) {
    // Child sources are active by default since they represent available data
    isActive = true;
  }

  /// Set the parent site source reference
  void setParentSite(SiteSource parentSite) {
    _parentSiteRef = WeakReference(parentSite);
  }

  /// Get the parent site source (if available)
  SiteSource? get parentSite => _parentSiteRef?.target;

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

  /// Get the current username from the parent site source
  @override
  String? get currentUsername {
    final parentSite = this.parentSite;
    if (parentSite != null) {
      return parentSite.currentUsername;
    }
    return null;
  }

  /// Get whether the parent site source is currently disconnecting
  @override
  bool get isDisconnecting {
    final parentSite = this.parentSite;
    return parentSite?.isDisconnecting ?? false;
  }

  /// Create an AsyncRequest for the specified request type
  /// Overrides the base class method to create SiteAsyncRequest instances
  @override
  AsyncRequest? createRequest(RequestType requestType,
      [Map<String, dynamic>? data]) {
    // For now, we'll create a basic SiteAsyncRequest
    // In a real implementation, you would need to get the base URL from metadata or configuration
    final baseUrl = metadata['baseUrl'] as String? ?? 'https://api.example.com';

    return SiteAsyncRequest(
      baseUrl: baseUrl,
      requestType: requestType,
      data: data,
    );
  }

  //@override
  //void search() {
  //debugPrint('SiteChildSource.search() called for $typeDisplayName: $name');
  // Trigger search in the database controller
  //final api = OVApi();
  //final dbApi = api.plugins.getPublicApi('onis_database_plugin');
  //if (dbApi != null) {
  // This will trigger the search functionality in the database page
  //debugPrint('Triggering search for child source: $name');
  //}
  //}

  @override
  Future<void> disconnect() async {
    final parentSite = this.parentSite;
    if (parentSite != null) {
      return parentSite.disconnect();
    }
  }
}

class SiteSource extends DatabaseSource {
  /// Public constructor for a site source (without parent)
  /// Parent relationships should be managed by DatabaseSourceManager
  SiteSource({required super.uid, required super.name, super.metadata})
      : super();

  // Track last used credentials and pending login per source
  String? lastUsername;
  String? lastPassword;
  bool lastRemember = false;
  bool isLoggingIn = false;
  bool _isDisconnecting = false;

  /// Map to store SiteAsyncRequest instances
  /// First key: source UID, Second key: RequestType
  final Map<String, Map<RequestType, List<SiteAsyncRequest>>> requests = {};

  /// Get the current logged-in username (if any)
  @override
  String? get currentUsername => lastUsername;

  /// Get whether the source is currently disconnecting
  @override
  bool get isDisconnecting => _isDisconnecting;

  /// Get whether this source is a root site source (always true for SiteSource)
  bool get isRootSite => true;

  /// Create an AsyncRequest for the specified request type
  /// Overrides the base class method to create SiteAsyncRequest instances
  @override
  AsyncRequest? createRequest(RequestType requestType,
      [Map<String, dynamic>? data]) {
    // For now, we'll create a basic SiteAsyncRequest
    // In a real implementation, you would need to get the base URL from metadata or configuration
    final baseUrl = metadata['baseUrl'] as String? ?? 'https://api.example.com';

    return SiteAsyncRequest(
      baseUrl: baseUrl,
      requestType: requestType,
      data: data,
    );
  }

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
    if (_isDisconnecting) return;
    _isDisconnecting = true;
    notifyListeners();

    // Emit disconnection event and wait for subscribers to complete
    await emitDisconnecting();

    // Simulate slow server response for disconnect
    //await Future.delayed(const Duration(seconds: 10));

    // Remove all child sources that were created during login
    final api = OVApi();
    final manager = api.sources;

    // Get all child sources of this site source using weak references
    final childSources = manager.allSources
        .where((source) =>
            source is SiteChildSource && (source).parentSite == this)
        .toList();

    // Remove each child source
    for (final childSource in childSources) {
      manager.removeSource(childSource);
    }

    // Mark source as disconnected
    isActive = false;
    lastUsername = null;
    lastPassword = null;
    lastRemember = false;
    isLoggingIn = false;
    _isDisconnecting = false;

    debugPrint(
        'Disconnected from site: $name (removed ${childSources.length} child sources)');

    notifyListeners();

    // Check and fix selection after disconnect completes
    // Use the current site UID for selection logic
    final dbApi = api.plugins.getPublicApi('onis_database_plugin');
    if (dbApi != null) {
      dbApi.checkAndFixSelection(uid);
    }
  }

  /// Mock login: optionally store credentials, wait 10 seconds, then mark active
  Future<void> login({
    required String username,
    required String password,
    required bool remember,
  }) async {
    lastUsername = username;
    lastPassword = password;
    lastRemember = remember;
    isLoggingIn = true;
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
    createChildSources();

    // Auto-expand the site source node in the source tree
    final api = OVApi();
    final dbApi = api.plugins.getPublicApi('onis_database_plugin');
    if (dbApi != null) {
      dbApi.expandSourceNode(uid, expand: true, expandChildren: true);
    }

    // Reset logging-in flag
    isLoggingIn = false;
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
          final initialUsername = isLoggingIn
              ? (lastUsername ?? saved?.username)
              : (saved?.username);
          final initialPassword = isLoggingIn
              ? (lastPassword ?? saved?.password)
              : (saved?.password);
          final initialRemember =
              isLoggingIn ? lastRemember : (saved?.remember ?? false);
          return SiteServerLoginPanel(
            initialUsername: initialUsername,
            initialPassword: initialPassword,
            initialRemember: initialRemember,
            initialSubmitting: isLoggingIn,
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

  //@override
  //void search() {
  // Site source specific open/search implementation
  //debugPrint('SiteSource.search() called for source: $name');
  // TODO: Implement site-specific search functionality
  // This could open a search dialog, navigate to a search page, etc.

  // Generate 500 studies with random patient IDs for realistic testing
  /*for (int i = 1; i <= 500; i++) {
      final modality = modalities[i % modalities.length];
      final status = statuses[i % statuses.length];
      final sex = sexes[i % sexes.length];
      final birthYear = 1950 + (i % 50);
      final birthMonth = 1 + (i % 12);
      final birthDay = 1 + (i % 28);
      final studyYear = 2020 + (i % 5);
      final studyMonth = 1 + (i % 12);
      final studyDay = 1 + (i % 28);

      dummyStudies.add(Study(
        id: 'ST_SEARCH_${i.toString().padLeft(3, '0')}',
        name: 'Patient ${i.toString().padLeft(3, '0')}',
        sex: sex,
        birthDate: DateTime(birthYear, birthMonth, birthDay),
        patientId: 'P${(100000 + random.nextInt(900000)).toString()}',
        studyDate:
            '$studyYear-${studyMonth.toString().padLeft(2, '0')}-${studyDay.toString().padLeft(2, '0')}',
        modality: modality,
        status: status,
      ));*/
  //}

  void createChildSources() {
    // Create partition source as a child of this site source

    final partitionsFolder = SiteChildSource(
      uid: '${uid}_partitions',
      name: 'Partitions',
      type: SiteChildSourceType.partitionFolder,
      metadata: {
        'type': 'partition_list',
        'parent_site': uid,
      },
    );
    partitionsFolder.setParentSite(this);
    OVApi().sources.registerSource(partitionsFolder, parentUid: uid);

    final partition1 = SiteChildSource(
      uid: '${uid}_partition1',
      name: 'Partition 1',
      type: SiteChildSourceType.partition,
      metadata: {
        'type': 'partition',
        'parent_site': uid,
        'description': 'Main clinical data partition',
        'size': '2.5 TB',
      },
    );
    partition1.setParentSite(this);
    OVApi().sources.registerSource(partition1, parentUid: partitionsFolder.uid);

    final partition2 = SiteChildSource(
      uid: '${uid}_partition2',
      name: 'Partition 2',
      type: SiteChildSourceType.partition,
      metadata: {
        'type': 'partition',
        'parent_site': uid,
        'description': 'Research and development data',
        'size': '1.8 TB',
      },
    );
    partition2.setParentSite(this);
    OVApi().sources.registerSource(partition2, parentUid: partitionsFolder.uid);

    debugPrint('Created child sources for site: $name');
    debugPrint('- Partitions folder: ${partitionsFolder.name}');
    debugPrint('- Partitions: ${partition1.name}, ${partition2.name}');
  }
}
