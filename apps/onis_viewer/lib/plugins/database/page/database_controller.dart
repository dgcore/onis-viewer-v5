import 'dart:math';

import 'package:flutter/material.dart';

import '../../../api/core/ov_api_core.dart';
import '../../../api/request/async_request.dart';
import '../../../core/database_source.dart';
import '../../../core/models/study.dart';

class DatabaseController extends ChangeNotifier {
  // Studies per source: Map<sourceUid, List<Study>>
  final Map<String, List<Study>> _studiesBySource = {};
  // Selected studies per source: Map<sourceUid, List<Study>>
  final Map<String, List<Study>> _selectedStudiesBySource = {};
  // Scroll positions per source: Map<sourceUid, double>
  final Map<String, double> _scrollPositionsBySource = {};
  // Pending requests per source and request type: Map<sourceUid, Map<RequestType, AsyncRequest?>>
  final Map<String, Map<RequestType, AsyncRequest?>> _pendingRequests = {};

  String _searchQuery = '';

  // Callback for showing error messages
  final Function(String message)? _showError;

  // Constructor with optional error callback
  DatabaseController({Function(String message)? showError})
      : _showError = showError;

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
    // Listen to source removal events to clear cache
    final api = OVApi();
    api.sources.onSourceUnregistered.listen(_onSourceRemoved);

    // Listen to source registration events to clear cache for new sources
    api.sources.onSourceRegistered.listen(_onSourceRegistered);

    // No dummy studies - studies will be loaded per source as needed
    debugPrint('DatabaseController initialized');
  }

  /// Handle source removal by clearing its cached data
  void _onSourceRemoved(DatabaseSource source) {
    debugPrint('Source removed, clearing cache for: ${source.uid}');
    clearStudiesForSource(source.uid);
    _scrollPositionsBySource.remove(source.uid);
  }

  /// Handle source registration by clearing any existing cache for the new source
  void _onSourceRegistered(DatabaseSource source) {
    debugPrint(
        'Source registered, clearing any existing cache for: ${source.uid}');
    clearStudiesForSource(source.uid);
    _scrollPositionsBySource.remove(source.uid);
  }

  @override
  Future<void> dispose() async {
    // Cancel all pending requests
    for (final sourceUid in _pendingRequests.keys.toList()) {
      await _cancelAllRequestsForSource(sourceUid);
    }
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

  /// Cancel a pending request for a specific source and request type
  Future<void> _cancelRequest(String sourceUid, RequestType requestType) async {
    final sourceRequests = _pendingRequests[sourceUid];
    if (sourceRequests != null) {
      final request = sourceRequests[requestType];
      if (request != null) {
        debugPrint(
            'Cancelling pending request for source: $sourceUid, type: $requestType');
        await request.cancel();
        sourceRequests[requestType] = null;
      }
    }
  }

  /// Cancel all pending requests for a specific source
  Future<void> _cancelAllRequestsForSource(String sourceUid) async {
    final sourceRequests = _pendingRequests[sourceUid];
    if (sourceRequests != null) {
      for (final requestType in sourceRequests.keys.toList()) {
        final request = sourceRequests[requestType];
        if (request != null) {
          debugPrint(
              'Cancelling pending request for source: $sourceUid, type: $requestType');
          await request.cancel();
          sourceRequests[requestType] = null;
        }
      }
    }
  }

  /// Parse studies from response data
  List<Study> _parseStudiesFromResponse(Map<String, dynamic>? data) {
    if (data == null || !data.containsKey('studies')) {
      return [];
    }

    final studiesList = data['studies'] as List?;
    if (studiesList == null) {
      return [];
    }

    return studiesList.map((studyData) {
      return Study.fromMap(studyData as Map<String, dynamic>);
    }).toList();
  }

  /// Show error message using the callback
  void _showErrorMessage(String message) {
    if (_showError != null) {
      _showError(message);
    } else {
      debugPrint('Error: $message');
    }
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

    // 1. Cancel any pending request for this source
    await _cancelAllRequestsForSource(sourceUid);

    // 2. Clear existing studies for this source
    clearStudiesForSource(sourceUid);

    // 3. Get the specific source by sourceUid
    final api = OVApi();
    final manager = api.sources;
    final source =
        manager.allSources.where((s) => s.uid == sourceUid).firstOrNull;

    if (source == null) {
      _showErrorMessage('Source not found for sourceUid: $sourceUid');
      return;
    }

    // 4. Create search request using the source's createRequest method
    AsyncRequest? request;
    try {
      request = source.createRequest(RequestType.findStudies, {
        'query': _searchQuery,
        'sourceUid': sourceUid,
      });

      if (request == null) {
        _showErrorMessage('Source does not support search requests');
        return;
      }
    } catch (e) {
      _showErrorMessage('Failed to create search request: $e');
      return;
    }

    // 5. Track the request and send it
    if (!_pendingRequests.containsKey(sourceUid)) {
      _pendingRequests[sourceUid] = {};
    }
    _pendingRequests[sourceUid]![RequestType.findStudies] = request;

    try {
      //final response = await request.send();

      // 6. Handle the response
      /*if (response.isSuccess) {
        final studies = _parseStudiesFromResponse(response.data);
        addStudiesToSource(sourceUid, studies);
        debugPrint(
            'Added ${studies.length} studies from search for source: $sourceUid');
      } else {
        _showErrorMessage(response.errorMessage ?? 'Search failed');
      }*/

      // Generate 500 studies with random patient IDs for realistic testing
      final modalities = [
        'CT',
        'MR',
        'US',
        'PT',
        'NM',
        'RF',
        'OT',
        'RT',
        'OT',
        'OT'
      ];
      final statuses = [
        'COMPLETED',
        'IN_PROGRESS',
        'CANCELLED',
        'PENDING',
        'ERROR'
      ];
      final sexes = ['M', 'F'];
      final random = Random();
      final List<Study> dummyStudies = [];
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
    } catch (e) {
      _showErrorMessage('Search error: $e');
    } finally {
      // 7. Clear the pending request
      _pendingRequests[sourceUid]![RequestType.findStudies] = null;
    }
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
