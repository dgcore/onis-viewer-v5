import 'package:flutter/material.dart';
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const OnisViewerHomePage(title: 'ONIS Viewer - Test FFI'),
    );
  }
}

class OnisViewerHomePage extends StatefulWidget {
  const OnisViewerHomePage({super.key, required this.title});

  final String title;

  @override
  State<OnisViewerHomePage> createState() => _OnisViewerHomePageState();
}

class _OnisViewerHomePageState extends State<OnisViewerHomePage> {
  String _version = 'Non initialisé';
  String _name = 'Non initialisé';
  int _result = 0;
  final int _a = 5;
  final int _b = 3;

  @override
  void initState() {
    super.initState();
    _initializeFFI();
  }

  void _initializeFFI() {
    try {
      OnisCore.initialize();
      setState(() {
        _version = OnisCore.getVersion();
        _name = OnisCore.getName();
        _result = OnisCore.add(_a, _b);
      });
    } catch (e) {
      setState(() {
        _version = 'Erreur: $e';
        _name = 'Erreur: $e';
        _result = -1;
      });
    }
  }

  void _testAddition() {
    try {
      final result = OnisCore.add(_a, _b);
      setState(() {
        _result = result;
      });
    } catch (e) {
      setState(() {
        _result = -1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test d\'intégration FFI C++',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text('Nom du logiciel: $_name'),
                    Text('Version: $_version'),
                    const SizedBox(height: 16),
                    Text(
                      'Test d\'addition:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Row(
                      children: [
                        Text('$_a + $_b = $_result'),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _testAddition,
                          child: const Text('Recalculer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prochaines étapes',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    const Text('• Implémenter le chargement DICOM'),
                    const Text('• Ajouter la visualisation d\'images'),
                    const Text('• Intégrer les annotations'),
                    const Text('• Ajouter le streaming'),
                    const Text('• Implémenter les hanging protocols'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
