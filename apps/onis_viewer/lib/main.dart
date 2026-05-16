import 'dart:convert';
import "dart:io";

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:onis_viewer/api/core/ov_api_core.dart';
import 'package:onis_viewer/app/onis_viewer_app.dart';
import 'package:onis_viewer/core/constants.dart';
import 'package:onis_viewer/core/monitor/monitor.dart';
import 'package:onis_viewer/core/monitor/monitor_widget.dart';
import 'package:onis_viewer/core/theme/app_theme.dart';
import 'package:window_manager/window_manager.dart';

void main(List<String> args) async {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    HttpOverrides.global = _MyHttpOverrides();
  }

  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('main args: $args');

  // desktop_multi_window launches sub-window isolates with:
  // [0] = "multi_window", [1] = windowId, [2] = payload
  final isSubWindowLaunch = args.length >= 3 && args[0] == 'multi_window';
  if (isSubWindowLaunch) {
    final engineId = int.tryParse(args[1]) ?? 1;
    OVApi.registerSubWindowEngineId(engineId);
    runApp(DisplayWindowApp(
      windowArgs: args[2],
      flutterEngineInstanceId: engineId,
    ));
    return;
  }

  // window_manager must only run in the main isolate.
  await windowManager.ensureInitialized();
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

class _DisplayWindowPageState extends State<DisplayWindowPage> {
  final OVApi _api = OVApi();
  OsMonitor? _monitor;

  /// macOS secondary Flutter engines get [AppLifecycleState.hidden] when the
  /// app loses focus, which disables the frame pipeline and freezes the UI.
  /// https://github.com/flutter/flutter/issues/133533
  AppLifecycleListener? _macSubWindowLifecycleWorkaround;

  @override
  void initState() {
    super.initState();
    if (Platform.isMacOS && widget.flutterEngineInstanceId > 0) {
      _macSubWindowLifecycleWorkaround = AppLifecycleListener(
        onStateChange: (state) {
          if (state == AppLifecycleState.hidden) {
            // ignore: invalid_use_of_protected_member
            SchedulerBinding.instance.handleAppLifecycleStateChanged(
              AppLifecycleState.inactive,
            );
          }
        },
      );
    }
    _initializeDisplayWindow();
  }

  Future<void> _initializeDisplayWindow() async {
    try {
      await _applySubWindowChrome(
        jsonDecode(widget.windowArgs) as Map<String, dynamic>,
      );

      await _api.initialize(
        flutterEngineInstanceId: widget.flutterEngineInstanceId,
      );

      final monitorArgs = jsonDecode(widget.windowArgs) as Map<String, dynamic>;
      final labelIndex = (monitorArgs['labelIndex'] as num?)?.toInt();
      final monitors = _api.monitorConfiguration?.getActiveMonitors() ?? [];
      if (labelIndex != null) {
        for (final m in monitors) {
          if (m.getLabelIndex() == labelIndex) {
            _monitor = m;
            break;
          }
        }
        _monitor?.createWindow();
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e, st) {
      debugPrint('DisplayWindow initialization failed: $e\n$st');
    }
  }

  /// Secondary engines use [WindowController] only (not [window_manager]).
  Future<void> _applySubWindowChrome(Map<String, dynamic> monitorArgs) async {
    final labelIndex = monitorArgs['labelIndex'];
    final title = '${OnisViewerConstants.appName} — Monitor $labelIndex';
    final left = (monitorArgs['left'] as num?)?.toDouble() ?? 100;
    final top = (monitorArgs['top'] as num?)?.toDouble() ?? 100;
    final width = (monitorArgs['width'] as num?)?.toDouble() ?? 800;
    final height = (monitorArgs['height'] as num?)?.toDouble() ?? 600;

    final window =
        WindowController.fromWindowId(widget.flutterEngineInstanceId);
    await window.setFrame(Rect.fromLTWH(left, top, width, height));
    await window.setTitle(title);
    await window.show();
  }

  @override
  void dispose() {
    _macSubWindowLifecycleWorkaround?.dispose();
    _api.dispose();
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
