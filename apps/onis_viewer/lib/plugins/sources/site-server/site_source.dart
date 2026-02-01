import 'dart:core';

import 'package:flutter/material.dart';
import 'package:onis_viewer/core/error_codes.dart';
import 'package:onis_viewer/core/onis_exception.dart';
import 'package:onis_viewer/plugins/sources/site-server/credentials/credential_store.dart';
import 'package:onis_viewer/plugins/sources/site-server/ui/site_server_login_panel.dart';
import 'package:uuid_v4/uuid_v4.dart';

import '../../../api/request/async_request.dart';
import '../../../core/database_source.dart';
import 'request/site_async_request.dart';
import 'ui/site_server_connection_panel.dart';

class SiteSourceLoginState extends DatabaseSourceLoginState {
  SiteServerCredentials credentials =
      SiteServerCredentials(username: '', password: '', remember: false);
}

/// Represents different types of child sources that can be created under a site source
enum SiteChildSourceType {
  partition(1),
  album(2),
  smartAlbum(3),
  dicomPacs(4),
  dicomFolder(5),
  partitionFolder(6);

  const SiteChildSourceType(this.value);
  final int value;
}

/// A child source under a site source (partition, album, or DICOM PACS)
class SiteChildSource extends DatabaseSource {
  final SiteChildSourceType type;
  WeakReference<SiteSource>? _parentSiteRef;
  final DatabaseSourceLoginState _loginState = SiteSourceLoginState();

  static SiteChildSource createFromJson(Map<String, dynamic> data) {
    final typeValue = data['type'] as int;
    final type = SiteChildSourceType.values.firstWhere(
      (e) => e.value == typeValue,
      orElse: () => throw OnisException(
        OnisErrorCodes.invalidResponse,
        "Invalid site child source type: $typeValue",
      ),
    );

    SiteChildSource source = SiteChildSource(
      uid: UUIDv4().toString(),
      name: data["name"] as String,
      type: type,
    );
    return source;
  }

  SiteChildSource({
    required super.uid,
    required super.name,
    required this.type,
    super.metadata,
  }) {
    // Child sources are active by default since they represent available data
    //isActive = true;
  }

  /// Set the parent site source reference
  void setParentSite(SiteSource parentSite) {
    _parentSiteRef = WeakReference(parentSite);
  }

  /// Get the parent site source (if available)
  SiteSource? get parentSite => _parentSiteRef?.target;

  /// Get the login state from the parent site source
  @override
  DatabaseSourceLoginState get loginState => _loginState;

  /// Get the type as a display string
  String get typeDisplayName {
    switch (type) {
      case SiteChildSourceType.partition:
        return 'Partition';
      case SiteChildSourceType.album:
        return 'Album';
      case SiteChildSourceType.smartAlbum:
        return 'Smart Album';
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
      case SiteChildSourceType.smartAlbum:
        return Icons.photo_library;
      case SiteChildSourceType.dicomPacs:
        return Icons.medical_services;
      case SiteChildSourceType.dicomFolder:
        return Icons.folder_open;
      case SiteChildSourceType.partitionFolder:
        return Icons.folder_special;
    }
  }

  /// Get the current username from the parent site source
  /*@override
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
  }*/

  /// Create an AsyncRequest for the specified request type
  /// Overrides the base class method to create SiteAsyncRequest instances
  @override
  AsyncRequest? createRequest(RequestType requestType,
      [Map<String, dynamic>? data]) {
    // For now, we'll create a basic SiteAsyncRequest
    // In a real implementation, you would need to get the base URL from metadata or configuration
    //final baseUrl = metadata['baseUrl'] as String? ?? 'https://api.example.com';
    final baseUrl = 'https://127.0.0.1:5555';

    if (data != null) {
      switch (requestType) {
        case RequestType.findStudies:
          data["source"] = uid;
          data["type"] = type.value;
          data["limit"] = 100;
          break;
        default:
          break;
      }
    }

    return SiteAsyncRequest(
      baseUrl: baseUrl,
      requestType: requestType,
      data: data,
    );
  }

  @override
  Future<void> disconnect() async {
    final parentSite = this.parentSite;
    return parentSite?.disconnect();
  }

  Future<void> _disconnectBase() async {
    return super.disconnect();
  }
}

class SiteSource extends DatabaseSource {
  /// Public constructor for a site source (without parent)
  /// Parent relationships should be managed by DatabaseSourceManager
  SiteSource({required super.uid, required super.name, super.metadata})
      : super();

  /// Map to store SiteAsyncRequest instances
  //final Map<RequestType, List<AsyncRequest>> _requests = {};

  final DatabaseSourceLoginState _loginState = SiteSourceLoginState();

  @override
  DatabaseSourceLoginState get loginState => _loginState;

  @override
  DatabaseSource? get defaultSource {
    if (subSources.isNotEmpty) {
      if (subSources.first.subSources.isNotEmpty) {
        return subSources.first.subSources.first;
      }
      return subSources.first;
    }
    return this;
  }

  /// Get whether the source is currently disconnecting
  //@override
  //bool get isDisconnecting => _isDisconnecting;

  /// Get whether this source is a root site source (always true for SiteSource)
  //bool get isRootSite => true;

  /// Create an AsyncRequest for the specified request type
  /// Overrides the base class method to create SiteAsyncRequest instances
  @override
  AsyncRequest? createRequest(RequestType requestType,
      [Map<String, dynamic>? data]) {
    // Get the base URL from metadata or use default localhost server
    //final baseUrl = metadata['baseUrl'] as String? ?? 'https://127.0.0.1:5555';
    final baseUrl = 'https://127.0.0.1:5555';
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
    if (loginState.status == ConnectionStatus.disconnecting ||
        loginState.status == ConnectionStatus.disconnected) {
      return;
    }
    if (loginState.status == ConnectionStatus.loggingIn) {
      // We must wait for the login to complete
      await waitForPendingRequests();
    }

    // Send a logout request to the server if logged in
    if (loginState.status == ConnectionStatus.loggedIn) {
      // Send a logout request to the server:
      AsyncRequest? request;
      try {
        request = createRequest(RequestType.logout, {});
        if (request != null) {
          addRequest(request);
          await request.send();
        }
      } catch (e) {
        //print('Error sending logout request: $e');
      } finally {
        if (request != null) removeRequest(request);
      }
    }
    //loginState.setStatus(ConnectionStatus.disconnecting);
    // Disconnect all child sources and remove them from the manager
    for (final subSource in subSources) {
      await (subSource as SiteChildSource)._disconnectBase();
      manager?.removeSource(subSource);
    }
    await super.disconnect();
    manager?.onSourceDisconnected(this);
  }

  /// Update credentials (called when user types in login fields)
  /*void updateCredentials({
    String? username,
    String? password,
    bool? remember,
  }) {
    if (username != null) {
      lastUsername = username;
    }
    if (password != null) {
      lastPassword = password;
    }
    if (remember != null) {
      lastRemember = remember;
    }
    // Defer notifyListeners to avoid calling setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }*/

  /// Authenticate with the site server
  Future<void> login({
    required bool useKeyChain,
  }) async {
    final siteLoginState = loginState as SiteSourceLoginState;
    final credentials = siteLoginState.credentials;
    AsyncRequest? request;
    try {
      if (siteLoginState.status != ConnectionStatus.disconnected) {
        throw OnisException(
            OnisErrorCodes.logicError, "The source is not disconnected.");
      }
      // Create authentication request
      request = createRequest(RequestType.login, {
        'username': credentials.username,
        'password': credentials.password,
      });
      if (request == null) {
        throw Exception('Failed to create authentication request');
      }
      addRequest(request);

      // Send the authentication request and wait for response
      loginState.setStatus(ConnectionStatus.loggingIn, errorMessage: null);

      // TEST: Wait 10 seconds without blocking GUI
      //await Future.delayed(const Duration(seconds: 10));
      final response = await request.send();

      if (!response.isSuccess) {
        throw OnisException(
            OnisErrorCodes.invalidResponse, "${response.errorMessage}");
      }

      // Check if authentication was successful
      final data = response.data;
      if (data == null) {
        throw OnisException(
            OnisErrorCodes.invalidResponse, "Missing response from server");
      }

      loginState.setStatus(ConnectionStatus.loggedIn, errorMessage: null);

      // Store or clear credentials based on remember flag
      if (useKeyChain && credentials.remember) {
        await SiteServerCredentialStore.save(
          uid,
          username: credentials.username,
          password: credentials.password,
          remember: true,
        );
      } else {
        await SiteServerCredentialStore.clear(uid);
      }
      // Create child sources from the server response
      createChildSources(data['config']['sources']);
      manager?.onSourceConnected(this);
    } on OnisException catch (e) {
      loginState.setStatus(ConnectionStatus.disconnected,
          errorMessage: e.message);
    } catch (e) {
      loginState.setStatus(ConnectionStatus.disconnected,
          errorMessage: e.toString());
    } finally {
      if (request != null) removeRequest(request);
    }
  }

  @override
  Widget? buildLoginPanel(BuildContext context, bool useKeyChain) {
    final siteLoginState = loginState as SiteSourceLoginState;
    final credentials = siteLoginState.credentials;

    // Helper function to build the login panel with given initial values
    Widget buildPanel(
        String initialUsername, String initialPassword, bool initialRemember) {
      return AnimatedBuilder(
        animation: siteLoginState,
        builder: (context, _) => SiteServerLoginPanel(
          initialUsername: initialUsername,
          initialPassword: initialPassword,
          initialRemember: initialRemember,
          initialSubmitting:
              siteLoginState.status == ConnectionStatus.loggingIn,
          initialErrorMessage: siteLoginState.errorMessage,
          instanceName: name,
          onCredentialsChanged: (username, password, remember) {
            /*updateCredentials(
              username: username,
              password: password,
              remember: remember,
            );*/
          },
          onSubmitAsync: (username, password, remember) async {
            credentials.username = username;
            credentials.password = password;
            credentials.remember = remember;
            await login(useKeyChain: useKeyChain);
            siteLoginState.notifyListeners();
          },
        ),
      );
    }

    String initialUsername = credentials.username;
    String initialPassword = credentials.password;
    bool initialRemember = credentials.remember;

    return KeyedSubtree(
      key: ValueKey<String>('login-$uid'),
      child: useKeyChain
          ? FutureBuilder<SiteServerCredentials?>(
              future: SiteServerCredentialStore.load(uid),
              builder: (context, snapshot) {
                final saved = snapshot.data;
                // Always prefer lastUsername, lastPassword, lastRemember if they exist
                // This ensures credentials persist even after failed login attempts
                if (initialUsername.isEmpty) {
                  initialUsername = saved?.username ?? "";
                  initialPassword = saved?.password ?? "";
                  initialRemember = saved?.remember ?? false;
                }
                return buildPanel(
                    initialUsername, initialPassword, initialRemember);
              },
            )
          : buildPanel(
              initialUsername,
              initialPassword,
              initialRemember,
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

  void createAndRegisterChildSource(
      Map<String, dynamic> childData, DatabaseSource parent) {
    final childSource = SiteChildSource.createFromJson(childData);
    childSource.setParentSite(this);
    (childSource.loginState as SiteSourceLoginState).credentials =
        (loginState as SiteSourceLoginState).credentials;
    manager?.registerSource(childSource, parentUid: parent.uid);
    childSource.loginState.setStatus(ConnectionStatus.loggedIn);
    for (final nestedChild in childData['children']) {
      if (nestedChild is Map<String, dynamic>) {
        createAndRegisterChildSource(nestedChild, childSource);
      }
    }
  }

  void createChildSources(List<dynamic> sources) {
    for (final source in sources) {
      if (source['type'] == 0) {
        for (final child in source['children']) {
          createAndRegisterChildSource(child, this);
        }
      }
    }
  }
}
