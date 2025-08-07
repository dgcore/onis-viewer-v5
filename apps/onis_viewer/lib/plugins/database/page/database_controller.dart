import 'package:flutter/material.dart';

import '../models/study.dart';

/// Database model
class Database {
  final String id;
  final String name;
  final String path;
  final String type;
  final String status;
  final String size;

  const Database({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    required this.status,
    required this.size,
  });
}

/// Controller for database operations
class DatabaseController extends ChangeNotifier {
  final List<Database> _databases = [];
  final List<Study> _studies = [];
  Database? _selectedDatabase;
  final List<Study> _selectedStudies = []; // Changed from final to mutable
  String _searchQuery = '';

  // Getters
  List<Database> get databases => _databases;
  List<Study> get studies => _studies;
  Database? get selectedDatabase => _selectedDatabase;
  List<Study> get selectedStudies =>
      _selectedStudies; // Changed from Study? to List<Study>
  String get searchQuery => _searchQuery;

  /// Initialize the controller
  Future<void> initialize() async {
    // Load sample databases for demonstration
    _databases.addAll([
      const Database(
        id: '1',
        name: 'Sample Medical Images',
        path: '/path/to/medical/images',
        type: 'DICOM',
        status: 'Connected',
        size: '2.5 GB',
      ),
      const Database(
        id: '2',
        name: 'Patient Records',
        path: '/path/to/patient/records',
        type: 'SQLite',
        status: 'Connected',
        size: '1.8 GB',
      ),
      const Database(
        id: '3',
        name: 'Research Data',
        path: '/path/to/research/data',
        type: 'PostgreSQL',
        status: 'Disconnected',
        size: '5.2 GB',
      ),
    ]);

    // Auto-select the first database
    if (_databases.isNotEmpty) {
      _selectedDatabase = _databases.first;
      debugPrint('Auto-selected database: ${_selectedDatabase!.name}');
    }

    // Load sample studies for demonstration
    _studies.addAll([
      Study(
        id: 'ST001',
        name: 'John Doe',
        sex: 'M',
        birthDate: DateTime(1985, 3, 15),
        patientId: 'P001',
        studyDate: '2024-01-15',
        modality: 'CT',
        status: 'Completed',
      ),
      Study(
        id: 'ST002',
        name: 'Jane Smith',
        sex: 'F',
        birthDate: DateTime(1990, 7, 22),
        patientId: 'P002',
        studyDate: '2024-01-16',
        modality: 'MRI',
        status: 'In Progress',
      ),
      Study(
        id: 'ST003',
        name: 'Bob Johnson',
        sex: 'M',
        birthDate: DateTime(1978, 11, 8),
        patientId: 'P003',
        studyDate: '2024-01-17',
        modality: 'X-Ray',
        status: 'Completed',
      ),
      Study(
        id: 'ST004',
        name: 'Alice Brown',
        sex: 'F',
        birthDate: DateTime(1995, 4, 12),
        patientId: 'P004',
        studyDate: '2024-01-18',
        modality: 'Ultrasound',
        status: 'Scheduled',
      ),
      Study(
        id: 'ST005',
        name: 'Charlie Wilson',
        sex: 'M',
        birthDate: DateTime(1982, 9, 30),
        patientId: 'P005',
        studyDate: '2024-01-19',
        modality: 'CT',
        status: 'Completed',
      ),
    ]);
  }

  /// Dispose the controller
  @override
  Future<void> dispose() async {
    // Clean up resources
    super.dispose();
  }

  /// Add a new database
  void addDatabase() {
    debugPrint('Add database action');
    // In a real implementation, this would show a dialog to add a database
  }

  /// Refresh databases
  void refreshDatabases() {
    debugPrint('Refresh databases action');
    // In a real implementation, this would reload databases from storage
  }

  /// Search databases
  void searchDatabases(String query) {
    _searchQuery = query;
    debugPrint('Search databases: $query');
    // In a real implementation, this would filter the database list
  }

  /// Select a database
  void selectDatabase(Database database) {
    _selectedDatabase = database;
    debugPrint('Selected database: ${database.name}');
  }

  /// Select a study
  void selectStudy(Study study) {
    _selectedStudies.clear();
    _selectedStudies.add(study);
    debugPrint('Selected study: ${study.name}');
    notifyListeners();
  }

  /// Select multiple studies
  void selectStudies(List<Study> studies) {
    _selectedStudies.clear();
    _selectedStudies.addAll(studies);
    debugPrint(
        'Selected ${studies.length} studies: ${studies.map((s) => s.name).join(', ')}');
    // Force a rebuild by notifying listeners
    notifyListeners();
  }

  /// Open a database
  void openDatabase(Database database) {
    debugPrint('Open database: ${database.name}');
    // In a real implementation, this would open the database
  }

  /// Export a database
  void exportDatabase(Database database) {
    debugPrint('Export database: ${database.name}');
    // In a real implementation, this would export the database
  }

  /// Delete a database
  void deleteDatabase(Database database) {
    debugPrint('Delete database: ${database.name}');
    // In a real implementation, this would delete the database
  }

  /// Show database settings
  void showSettings() {
    debugPrint('Show database settings');
    // In a real implementation, this would show settings dialog
  }

  // Toolbar action methods
  void quit() {
    debugPrint('Quit action');
    // In a real implementation, this would quit the application
  }

  void openPreferences() {
    debugPrint('Open preferences action');
    // In a real implementation, this would open preferences dialog
  }

  void importData() {
    debugPrint('Import data action');
    // In a real implementation, this would import data
  }

  void exportData() {
    debugPrint('Export data action');
    // In a real implementation, this would export data
  }

  void transferData() {
    debugPrint('Transfer data action');
    // In a real implementation, this would transfer data
  }

  void createCD() {
    debugPrint('Create CD action');
    // In a real implementation, this would create a CD
  }

  void openDatabaseFromToolbar() {
    debugPrint('Open database action');
    // In a real implementation, this would open a database
  }

  void search() {
    debugPrint('Search action');
    // In a real implementation, this would open search dialog
  }

  void stop() {
    debugPrint('Stop action');
    // In a real implementation, this would stop current operation
  }
}
