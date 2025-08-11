import 'dart:core';

import 'package:flutter/material.dart';

import '../../../core/database_source.dart';
import 'credentials/credential_store.dart';
import 'ui/site_server_connection_panel.dart';
import 'ui/site_server_login_panel.dart';

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
  String? get currentUsername => _lastUsername;

  /// Get whether the source is currently disconnecting
  bool get isDisconnecting => _isDisconnecting;

  /// Disconnect from the source
  Future<void> disconnect() async {
    _isDisconnecting = true;
    notifyListeners();

    // Simulate slow server response for disconnect
    await Future.delayed(const Duration(seconds: 10));

    // Mark source as disconnected
    isActive = false;
    _lastUsername = null;
    _lastPassword = null;
    _lastRemember = false;
    _isLoggingIn = false;
    _isDisconnecting = false;
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

    // Simulate slow server response
    await Future.delayed(const Duration(seconds: 1));

    // Mark source as connected
    isActive = true; // Triggers listeners via setter

    // Reset logging-in flag
    _isLoggingIn = false;
    notifyListeners();
  }

  @override
  Widget? buildLoginPanel(BuildContext context) {
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
  void search() {
    // Site source specific open/search implementation
    debugPrint('SiteSource.search() called for source: $name');
    // TODO: Implement site-specific search functionality
    // This could open a search dialog, navigate to a search page, etc.
  }
}
