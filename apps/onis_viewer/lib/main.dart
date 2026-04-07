import "dart:io";
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

void main() {
  // Set up SSL certificate validation override for desktop platforms
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    HttpOverrides.global = _MyHttpOverrides();
  }
  runApp(const OnisViewerApp());
}

/// HTTP overrides to ignore SSL certificate validation
class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) {
      return true;
    };
    return client;
  }
}
