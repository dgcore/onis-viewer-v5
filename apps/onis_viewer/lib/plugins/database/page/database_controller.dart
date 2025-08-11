import 'package:flutter/material.dart';

import '../../../core/models/study.dart';

/// Controller for database operations
class DatabaseController extends ChangeNotifier {
  final List<Study> _studies = [];
  final List<Study> _selectedStudies = [];
  String _searchQuery = '';

  // Getters
  List<Study> get studies => _studies;
  List<Study> get selectedStudies => _selectedStudies;
  String get searchQuery => _searchQuery;

  /// Initialize the controller
  Future<void> initialize() async {
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

  /// Search studies
  void searchStudies(String query) {
    _searchQuery = query;
    debugPrint('Search studies: $query');
    // In a real implementation, this would filter the study list
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
    notifyListeners();
  }

  // Toolbar action methods
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

  void openDatabaseFromToolbar() {
    debugPrint('Open database action');
    // In a real implementation, this would open a database
  }

  void search() {
    debugPrint('Search action');
    // In a real implementation, this would open search dialog
  }

  void showSettings() {
    debugPrint('Show database settings');
    // In a real implementation, this would show settings dialog
  }
}
