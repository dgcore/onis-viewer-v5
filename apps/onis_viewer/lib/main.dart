import "dart:io";

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:onis_viewer/api/core/ov_api_core.dart';
import 'package:onis_viewer/app/onis_viewer_app.dart';
import 'package:onis_viewer/core/constants.dart';
import 'package:onis_viewer/core/monitor/monitor_widget.dart';
import 'package:window_manager/window_manager.dart';

void main(List<String> args) async {
  // Set up SSL certificate validation override for desktop platforms
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    HttpOverrides.global = _MyHttpOverrides();
  }

  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  debugPrint('main args: $args');

  // desktop_multi_window launches sub-window isolates with:
  // [0] = "multi_window", [1] = windowId, [2] = payload
  final isSubWindowLaunch = args.length >= 3 && args[0] == 'multi_window';
  if (isSubWindowLaunch) {
    runApp(DisplayWindowApp(windowArgs: args[2]));
    return;
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

class DisplayWindowApp extends StatelessWidget {
  final String windowArgs;

  const DisplayWindowApp({
    super.key,
    required this.windowArgs,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DisplayWindowPage(windowArgs: windowArgs),
    );
  }
}

class DisplayWindowPage extends StatefulWidget {
  final String windowArgs;

  const DisplayWindowPage({
    super.key,
    required this.windowArgs,
  });

  @override
  State<DisplayWindowPage> createState() => _DisplayWindowPageState();
}

class _DisplayWindowPageState extends State<DisplayWindowPage>
    with WindowListener {
  //late final Map<String, dynamic> args;
  final OVApi _api = OVApi();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initializeDisplayWindow();
  }

  Future<void> _initializeDisplayWindow() async {
    try {
      await _api.initialize();
      DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
        if (call.method == 'onis/backend_identity') {
          return <String, dynamic>{
            'windowType': 'display',
            'backendVersion': _api.backend.backendVersion,
            'backendInstanceId': _api.backend.backendInstanceId,
            'fromWindowId': fromWindowId,
          };
        }
        return null;
      });
      await _configureWindow();
    } catch (e, st) {
      debugPrint('DisplayWindow initialization failed: $e\n$st');
      rethrow;
    }
  }

  Future<void> _configureWindow() async {
    windowManager.addListener(this);

    final double x = 100;
    //(args['x'] as num).toDouble();
    final double y = 100; //(args['y'] as num).toDouble();
    final double width = 800; //(args['width'] as num).toDouble();
    final double height = 600; //(args['height'] as num).toDouble();
    const options = WindowOptions(
      backgroundColor: Colors.black,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(options, () async {
      // Pseudo fullscreen robuste
      await windowManager.setBounds(
        Rect.fromLTWH(x, y, width, height),
      );

      await windowManager.setResizable(false);
      await windowManager.setMaximizable(false);
      await windowManager.setMinimizable(false);
      await windowManager.setClosable(false);
      await windowManager.show();
      await windowManager.focus();

    });
  }

  @override
  void dispose() {
    _api.dispose();
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        navigatorKey: navigatorKey,
        title: OnisViewerConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.dark(
            primary: OnisViewerConstants.primaryColor,
            secondary: OnisViewerConstants.secondaryColor,
            surface: OnisViewerConstants.surfaceColor,
          ),
          useMaterial3: true,
        ),
        home: OsMonitorWidget());
  }
}
