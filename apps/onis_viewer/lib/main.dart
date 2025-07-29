import 'package:flutter/material.dart';

import 'api/ov_api.dart';
import 'ffi/onis_ffi.dart';

void main() {
  runApp(const OnisViewerApp());
}

class OnisViewerApp extends StatelessWidget {
  const OnisViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ONIS Viewer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const OnisViewerHomePage(),
    );
  }
}

class OnisViewerHomePage extends StatefulWidget {
  const OnisViewerHomePage({super.key});

  @override
  State<OnisViewerHomePage> createState() => _OnisViewerHomePageState();
}

class _OnisViewerHomePageState extends State<OnisViewerHomePage> {
  String _ffiStatus = 'Initializing...';
  String _apiInfo = '';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize OVApi
    final api = OVApi();
    setState(() {
      _apiInfo = 'API: ${api.name} v${api.version}';
    });

    // Test FFI connection
    try {
      final ffi = OnisFFI();
      final result = await ffi.testConnection();
      setState(() {
        _ffiStatus = result;
      });
    } catch (e) {
      setState(() {
        _ffiStatus = 'FFI Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('ONIS Viewer - Test FFI'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome to ONIS Viewer',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              _apiInfo,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'FFI Status: $_ffiStatus',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            const Text(
              'This is a test application for ONIS Viewer v5',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
