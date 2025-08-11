import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/models/study.dart';

class DatabaseController extends ChangeNotifier {
  // Studies per source: Map<sourceUid, List<Study>>
  final Map<String, List<Study>> _studiesBySource = {};
  // Selected studies per source: Map<sourceUid, List<Study>>
  final Map<String, List<Study>> _selectedStudiesBySource = {};
  // Scroll positions per source: Map<sourceUid, double>
  final Map<String, double> _scrollPositionsBySource = {};
  String _searchQuery = '';

  // Getters
  String get searchQuery => _searchQuery;

  List<Study> getStudiesForSource(String sourceUid) {
    return _studiesBySource[sourceUid] ?? [];
  }

  List<Study> getSelectedStudiesForSource(String sourceUid) {
    return _selectedStudiesBySource[sourceUid] ?? [];
  }

  double getScrollPositionForSource(String sourceUid) {
    return _scrollPositionsBySource[sourceUid] ?? 0.0;
  }

  void saveScrollPositionForSource(String sourceUid, double position) {
    _scrollPositionsBySource[sourceUid] = position;
    debugPrint('Saved scroll position $position for source $sourceUid');
  }

  List<Study> get allStudies {
    return _studiesBySource.values.expand((studies) => studies).toList();
  }

  int get totalStudyCount {
    return _studiesBySource.values
        .fold(0, (sum, studies) => sum + studies.length);
  }

  Future<void> initialize() async {
    // No dummy studies - studies will be loaded per source as needed
    debugPrint('DatabaseController initialized');
  }

  @override
  Future<void> dispose() async {
    super.dispose();
  }

  Future<void> loadStudiesForSource(String sourceUid) async {
    debugPrint('Loading studies for source: $sourceUid');
    _studiesBySource[sourceUid] = [];
    _selectedStudiesBySource[sourceUid] = [];
    notifyListeners();
  }

  void clearStudiesForSource(String sourceUid) {
    _studiesBySource.remove(sourceUid);
    _selectedStudiesBySource.remove(sourceUid);
    notifyListeners();
  }

  void addStudiesToSource(String sourceUid, List<Study> studies) {
    if (!_studiesBySource.containsKey(sourceUid)) {
      _studiesBySource[sourceUid] = [];
    }
    _studiesBySource[sourceUid]!.addAll(studies);
    notifyListeners();
  }

  void searchStudies(String query) {
    _searchQuery = query;
    debugPrint('Search studies: $query');
  }

  void selectStudy(String sourceUid, Study study) {
    if (!_selectedStudiesBySource.containsKey(sourceUid)) {
      _selectedStudiesBySource[sourceUid] = [];
    }
    _selectedStudiesBySource[sourceUid]!.clear();
    _selectedStudiesBySource[sourceUid]!.add(study);
    debugPrint('Selected study: ${study.name} for source: $sourceUid');
    notifyListeners();
  }

  void selectStudies(String sourceUid, List<Study> studies) {
    if (!_selectedStudiesBySource.containsKey(sourceUid)) {
      _selectedStudiesBySource[sourceUid] = [];
    }
    _selectedStudiesBySource[sourceUid]!.clear();
    _selectedStudiesBySource[sourceUid]!.addAll(studies);
    debugPrint('Selected ${studies.length} studies for source: $sourceUid');
    notifyListeners();
  }

  void clearSelectedStudies(String sourceUid) {
    _selectedStudiesBySource[sourceUid]?.clear();
    notifyListeners();
  }

  Future<void> onSearch(String sourceUid) async {
    debugPrint('Searching studies for source: $sourceUid');
    clearStudiesForSource(sourceUid);

    final dummyStudies = <Study>[];
    final modalities = ['CT', 'MRI', 'X-Ray', 'Ultrasound', 'PET'];
    final statuses = ['Completed', 'In Progress', 'Scheduled', 'Cancelled'];
    final sexes = ['M', 'F'];
    final Random random = Random(DateTime.now().millisecondsSinceEpoch);

    // Generate 500 studies with random patient IDs for realistic testing
    for (int i = 1; i <= 500; i++) {
      final modality = modalities[i % modalities.length];
      final status = statuses[i % statuses.length];
      final sex = sexes[i % sexes.length];
      final birthYear = 1950 + (i % 50);
      final birthMonth = 1 + (i % 12);
      final birthDay = 1 + (i % 28);
      final studyYear = 2020 + (i % 5);
      final studyMonth = 1 + (i % 12);
      final studyDay = 1 + (i % 28);

      dummyStudies.add(Study(
        id: 'ST_SEARCH_${i.toString().padLeft(3, '0')}',
        name: 'Patient ${i.toString().padLeft(3, '0')}',
        sex: sex,
        birthDate: DateTime(birthYear, birthMonth, birthDay),
        patientId: 'P${(100000 + random.nextInt(900000)).toString()}',
        studyDate:
            '$studyYear-${studyMonth.toString().padLeft(2, '0')}-${studyDay.toString().padLeft(2, '0')}',
        modality: modality,
        status: status,
      ));
    }

    addStudiesToSource(sourceUid, dummyStudies);
    debugPrint(
        'Added ${dummyStudies.length} studies from search for source: $sourceUid');
  }

  // Toolbar action methods
  void openPreferences() {
    debugPrint('Open preferences action');
  }

  void importData() {
    debugPrint('Import data action');
  }

  void exportData() {
    debugPrint('Export data action');
  }

  void transferData() {
    debugPrint('Transfer data action');
  }

  void openDatabaseFromToolbar() {
    debugPrint('Open database action');
  }

  void search() {
    debugPrint('Search action');
  }

  void showSettings() {
    debugPrint('Show database settings');
  }
}
