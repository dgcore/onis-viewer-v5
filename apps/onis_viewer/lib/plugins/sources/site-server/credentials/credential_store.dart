import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SiteServerCredentials {
  final String username;
  final String password;
  final bool remember;
  const SiteServerCredentials({
    required this.username,
    required this.password,
    required this.remember,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
        'remember': remember,
      };

  static SiteServerCredentials fromJson(Map<String, dynamic> json) =>
      SiteServerCredentials(
        username: json['username'] as String? ?? '',
        password: json['password'] as String? ?? '',
        remember: json['remember'] as bool? ?? false,
      );
}

class SiteServerCredentialStore {
  static const _storage = FlutterSecureStorage();
  static const _prefix = 'site_server_credentials_';
  static final Map<String, String> _memoryFallback = {};

  static String _key(String sourceUid) => '$_prefix$sourceUid';

  static Future<SiteServerCredentials?> load(String sourceUid) async {
    final key = _key(sourceUid);
    try {
      final raw = await _storage.read(key: key);
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return SiteServerCredentials.fromJson(map);
    } on PlatformException {
      final raw = _memoryFallback[key];
      if (raw == null) return null;
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return SiteServerCredentials.fromJson(map);
      } catch (_) {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(
    String sourceUid, {
    required String username,
    required String password,
    required bool remember,
  }) async {
    final key = _key(sourceUid);
    final data = SiteServerCredentials(
      username: username,
      password: password,
      remember: remember,
    );
    final raw = jsonEncode(data.toJson());
    try {
      await _storage.write(key: key, value: raw);
    } on PlatformException {
      // Fallback to in-memory store to avoid crashes in dev without entitlements
      _memoryFallback[key] = raw;
    }
  }

  static Future<void> clear(String sourceUid) async {
    final key = _key(sourceUid);
    try {
      await _storage.delete(key: key);
    } on PlatformException {
      _memoryFallback.remove(key);
    }
  }

  static Future<bool> has(String sourceUid) async {
    final key = _key(sourceUid);
    try {
      final v = await _storage.read(key: key);
      return v != null;
    } on PlatformException {
      return _memoryFallback.containsKey(key);
    }
  }
}
