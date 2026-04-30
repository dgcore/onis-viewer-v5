import 'dart:convert';
import "dart:io";

import 'package:flutter/material.dart';
import 'package:onis_viewer/api/core/ov_api_core.dart';
import 'package:onis_viewer/app/onis_viewer_app.dart';
import 'package:onis_viewer/core/constants.dart';
import 'package:onis_viewer/core/monitor/monitor.dart';
import 'package:onis_viewer/core/monitor/monitor_widget.dart';
import 'package:onis_viewer/core/theme/app_theme.dart';
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
    final engineId = int.tryParse(args[1]) ?? 1;
    runApp(DisplayWindowApp(
      windowArgs: args[2],
      flutterEngineInstanceId: engineId,
    ));
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
  final int flutterEngineInstanceId;

  const DisplayWindowApp({
    super.key,
    required this.windowArgs,
    required this.flutterEngineInstanceId,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: OnisViewerConstants.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: OnisViewerConstants.primaryColor,
          secondary: OnisViewerConstants.secondaryColor,
          surface: OnisViewerConstants.surfaceColor,
        ),
        extensions: [
          AppTheme.fallback(
            Brightness.dark,
            const ColorScheme.dark(
              primary: OnisViewerConstants.primaryColor,
              secondary: OnisViewerConstants.secondaryColor,
              surface: OnisViewerConstants.surfaceColor,
            ),
          ),
        ],
        useMaterial3: true,
      ),
      home: DisplayWindowPage(
        windowArgs: windowArgs,
        flutterEngineInstanceId: flutterEngineInstanceId,
      ),
    );
  }
}

class DisplayWindowPage extends StatefulWidget {
  final String windowArgs;
  final int flutterEngineInstanceId;

  const DisplayWindowPage({
    super.key,
    required this.windowArgs,
    required this.flutterEngineInstanceId,
  });

  @override
  State<DisplayWindowPage> createState() => _DisplayWindowPageState();
}

class _DisplayWindowPageState extends State<DisplayWindowPage>
    with WindowListener {
  //late final Map<String, dynamic> args;
  final OVApi _api = OVApi();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  OsMonitor? _monitor;

  @override
  void initState() {
    super.initState();
    _initializeDisplayWindow();
  }

  Future<void> _initializeDisplayWindow() async {
    try {
      await _api.initialize(
        flutterEngineInstanceId: widget.flutterEngineInstanceId,
      );
      final monitorArgs = jsonDecode(widget.windowArgs);
      final labelIndex = monitorArgs['labelIndex'];
      final monitors = _api.monitorConfiguration?.getActiveMonitors() ?? [];
      if (monitors.isNotEmpty) {
        _monitor = monitors
            .firstWhere((monitor) => monitor.getLabelIndex() == labelIndex);
        if (_monitor != null) {
          _monitor?.createWindow();
        }
        if (mounted) {
          setState(() {});
        }
      }
      /*_api.attachMultiWindowMessageHandler((call, fromWindowId) async {
        if (call.method == 'onis/backend_identity') {
          return <String, dynamic>{
            'windowType': 'display',
            'backendVersion': _api.backend.backendVersion,
            'backendInstanceId': _api.backend.backendInstanceId,
            'fromWindowId': fromWindowId,
          };
        }
        return null;
      });*/
      await _configureWindow();
    } catch (e, st) {
      debugPrint('DisplayWindow initialization failed: $e\n$st');
      rethrow;
    }
  }

  Future<void> _configureWindow() async {
    windowManager.addListener(this);

    final monitorArgs = jsonDecode(widget.windowArgs);
    double width = (monitorArgs["width"] as num).toDouble();
    double height = (monitorArgs["height"] as num).toDouble();
    final double x = 100;
    final double y = 100; //(args['y'] as num).toDouble();

    const options = WindowOptions(
      backgroundColor: Colors.black,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
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
    final monitorWnd = _monitor?.getWindow();
    return Scaffold(
      body: monitorWnd != null
          ? OsMonitorWidget(monitorWnd: monitorWnd)
          : const SizedBox.shrink(),
    );
  }
}
