import "dart:io";

import 'package:flutter/material.dart';
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

  if (args.isNotEmpty) {
    runApp(DisplayWindowApp(windowArgs: args.first));
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
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    //args = jsonDecode(widget.windowArgs) as Map<String, dynamic>;
    _configureWindow();
  }

  Future<void> _configureWindow() async {
    windowManager.addListener(this);

    final double x = 100;
    //(args['x'] as num).toDouble();
    final double y = 100; //(args['y'] as num).toDouble();
    final double width = 800; //(args['width'] as num).toDouble();
    final double height = 600; //(args['height'] as num).toDouble();
    final bool fullscreen = false;
    //args['fullscreen'] as bool? ?? false;

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

      /*if (fullscreen) {
        await windowManager.setFullScreen(true);
      }*/
    });
  }

  @override
  void dispose() {
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
