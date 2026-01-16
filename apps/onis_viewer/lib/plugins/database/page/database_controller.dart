/*import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../api/request/async_request.dart';
import '../../../core/database_source.dart';
import '../../../core/models/study.dart';

class DatabaseSourceState {
  DatabaseSourceState(DatabaseSource source) {
    loginState = source.createLoginState();
  }
  DatabaseSourceLoginState? loginState;
  bool isConnected = false;
  List<Study> studies = [];
  List<Study> selectedStudies = [];
  double scrollPosition = 0.0;
  Map<RequestType, AsyncRequest?> pendingRequests = {};
}

class DatabaseController extends ChangeNotifier {
  // TO DELETE PROBABLY:
  String _searchQuery = '';
  //final Function(String message)? _showError;

  late final DatabaseSourceManager _databaseSourceManager;
  final Map<String, DatabaseSourceState> _sourceStates = {};

  /// Stream subscription for disconnection events
  //StreamSubscription<String>? _disconnectionSubscription;

  /// Stream subscriptions for source registration events
  StreamSubscription<DatabaseSource>? _sourceRegisteredSubscription;
  StreamSubscription<DatabaseSource>? _sourceUnregisteredSubscription;

  /// Constructor
  DatabaseController() {
    //_instances.add(this);

    // Subscribe to disconnection events and store the subscription
    /*_disconnectionSubscription =
        DatabaseSource.subscribeToDisconnection(_onSourceDisconnecting);*/
  }

  /// Initialize the controller
  Future<void> initialize() async {
    //final api = OVApi();
    _databaseSourceManager = DatabaseSourceManager();
    _sourceRegisteredSubscription =
        _databaseSourceManager.onSourceRegistered.listen(_onSourceRegistered);
    _sourceUnregisteredSubscription = _databaseSourceManager
        .onSourceUnregistered
        .listen(_onSourceUnregistered);
    // Register the existing sources:
    final sources = _databaseSourceManager.allSources;
    for (final source in sources) {
      _onSourceRegistered(source);
    }
  }

  /// Dispose the controller
  @override
  Future<void> dispose() async {
    await _databaseSourceManager.cleanExit();
    await _sourceRegisteredSubscription?.cancel();
    await _sourceUnregisteredSubscription?.cancel();
    _sourceRegisteredSubscription = null;
    _sourceUnregisteredSubscription = null;

    // Unsubscribe from disconnection events
    /*await DatabaseSource.unsubscribeToDisconnection(_disconnectionSubscription);
    _disconnectionSubscription = null;*/

    // Cancel all pending requests
    /*for (final sourceUid in _pendingRequests.keys.toList()) {
      await _cancelAllRequestsForSource(sourceUid);
    }*/
    super.dispose();
  }

  void _onSourceRegistered(DatabaseSource source) {
    _sourceStates[source.uid] = DatabaseSourceState(source);
  }

  void _onSourceUnregistered(DatabaseSource source) {
    _sourceStates.remove(source.uid);
  }

  DatabaseSourceManager get sources => _databaseSourceManager;

  /// Handle source disconnection events
  /*void _onSourceDisconnecting(String sourceUid) {
    debugPrint(
        'Source disconnecting: $sourceUid - cancelling pending requests');

    // Handle the async operations without making this method async
    _handleDisconnectionCleanup(sourceUid).catchError((error) {
      debugPrint(
          'Error during disconnection cleanup for source $sourceUid: $error');
      // Still signal completion even if there was an error
      DatabaseSource.signalDisconnectionComplete(sourceUid);
    });
  }

  /// Handle the async cleanup operations for disconnection
  Future<void> _handleDisconnectionCleanup(String sourceUid) async {
    try {
      // Get all child sources of the disconnecting source
      final api = OVApi();
      final source = api.sources.findSourceByUid(sourceUid);
      final childSources =
          source != null ? [source, ...source.allDescendants] : [];

      // Cancel requests and clear data for each child source
      for (final childSource in childSources) {
        await _cancelAllRequestsForSource(childSource.uid);
        clearStudiesForSource(childSource.uid);
        clearSelectedStudies(childSource.uid);
      }

      debugPrint('Cleanup completed for disconnecting source: $sourceUid');

      // Signal that we've completed our cleanup
      DatabaseSource.signalDisconnectionComplete(sourceUid);
    } catch (e) {
      debugPrint(
          'Error during disconnection cleanup for source $sourceUid: $e');
      // Re-throw to be caught by the catchError in _onSourceDisconnecting
      rethrow;
    }
  }*/

  // Getters
  String get searchQuery => _searchQuery;

  DatabaseSourceState? _getSourceState(String sourceUid) {
    return _sourceStates.containsKey(sourceUid)
        ? _sourceStates[sourceUid]
        : null;
  }

  bool isConnected(String sourceUid) {
    final sourceState = _getSourceState(sourceUid);
    return sourceState?.isConnected ?? false;
  }

  List<Study> getStudiesForSource(String sourceUid) {
    final sourceState = _getSourceState(sourceUid);
    return sourceState?.studies ?? [];
  }

  bool hasSelectedStudies(String sourceUid) {
    final sourceState = _getSourceState(sourceUid);
    return sourceState?.selectedStudies.isNotEmpty ?? false;
  }

  List<Study> getSelectedStudiesForSource(String sourceUid) {
    final sourceState = _getSourceState(sourceUid);
    return sourceState?.selectedStudies ?? [];
  }

  double getScrollPositionForSource(String sourceUid) {
    final sourceState = _getSourceState(sourceUid);
    return sourceState?.scrollPosition ?? 0.0;
  }

  void saveScrollPositionForSource(String sourceUid, double position) {
    final sourceState = _getSourceState(sourceUid);
    if (sourceState != null) {
      sourceState.scrollPosition = position;
    }
  }

  DatabaseSourceLoginState? getLoginState(String sourceUid) {
    final sourceState = _getSourceState(sourceUid);
    return sourceState?.loginState;
  }

  //List<Study> get allStudies {
  //return _studiesBySource.values.expand((studies) => studies).toList();
  //return [];
  // }

  int get totalStudyCount {
    //return _studiesBySource.values
    //    .fold(0, (sum, studies) => sum + studies.length);
    return 0;
  }

  Future<void> loadStudiesForSource(String sourceUid) async {
    //_studiesBySource[sourceUid] = [];
    //_selectedStudiesBySource[sourceUid] = [];
    notifyListeners();
  }

  void clearStudiesForSource(String sourceUid) {
    //_studiesBySource.remove(sourceUid);
    //_selectedStudiesBySource.remove(sourceUid);
    notifyListeners();
  }

  void addStudiesToSource(String sourceUid, List<Study> studies) {
    //if (!_studiesBySource.containsKey(sourceUid)) {
    //  _studiesBySource[sourceUid] = [];
    //}
    //_studiesBySource[sourceUid]!.addAll(studies);
    notifyListeners();
  }

  void searchStudies(String query) {
    _searchQuery = query;
    debugPrint('Search studies: $query');
  }

  /// Cancel a pending request for a specific source and request type
  Future<void> _cancelRequest(String sourceUid, RequestType requestType) async {
    /*final sourceRequests = _pendingRequests[sourceUid];
    if (sourceRequests != null) {
      final request = sourceRequests[requestType];
      if (request != null) {
        debugPrint(
            'Cancelling pending request for source: $sourceUid, type: $requestType');
        await request.cancel();
        sourceRequests[requestType] = null;
      }
    }*/
  }

  /// Cancel all pending requests for a specific source
  Future<void> _cancelAllRequestsForSource(String sourceUid) async {
    /*final sourceRequests = _pendingRequests[sourceUid];
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
    }*/
  }

  /// Parse studies from response data
  List<Study> _parseStudiesFromResponse(Map<String, dynamic>? data) {
    /*if (data == null || !data.containsKey('studies')) {
      return [];
    }

    final studiesList = data['studies'] as List?;
    if (studiesList == null) {
      return [];
    }

    return studiesList.map((studyData) {
      return Study.fromMap(studyData as Map<String, dynamic>);
    }).toList();*/
    return [];
  }

  /// Show error message using the callback
  /*void _showErrorMessage(String message) {
    if (_showError != null) {
      _showError(message);
    } else {
      debugPrint('Error: $message');
    }
  }*/

  void selectStudy(String sourceUid, Study study) {
    /*if (!_selectedStudiesBySource.containsKey(sourceUid)) {
      _selectedStudiesBySource[sourceUid] = [];
    }
    _selectedStudiesBySource[sourceUid]!.clear();
    _selectedStudiesBySource[sourceUid]!.add(study);
    debugPrint('Selected study: ${study.name} for source: $sourceUid');*/
    notifyListeners();
  }

  void selectStudies(String sourceUid, List<Study> studies) {
    /*if (!_selectedStudiesBySource.containsKey(sourceUid)) {
      _selectedStudiesBySource[sourceUid] = [];
    }
    _selectedStudiesBySource[sourceUid]!.clear();
    _selectedStudiesBySource[sourceUid]!.addAll(studies);
    debugPrint('Selected ${studies.length} studies for source: $sourceUid');*/
    notifyListeners();
  }

  void clearSelectedStudies(String sourceUid) {
    //_selectedStudiesBySource[sourceUid]?.clear();
    notifyListeners();
  }

  Future<void> onSearch(String sourceUid) async {
    debugPrint('Searching studies for source: $sourceUid');

    // 1. Cancel any pending request for this source
    /*await _cancelAllRequestsForSource(sourceUid);

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
      //debugPrint('Delaying for 10 seconds');
      //await Future.delayed(const Duration(seconds: 10));
      //debugPrint('Delayed for 10 seconds');
      final response = await request.send();

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
    }*/
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

  /// Check if search is available for the given source
  /// Returns true if the source is connected
  bool canSearch(String sourceUid) {
    /*final api = OVApi();
    final source = api.sources.findSourceByUid(sourceUid);
    return source?.isActive ?? false;*/
    return false;
  }

  /// Check if import is available for the given source
  /// Returns true if the source is connected
  bool canImport(String sourceUid) {
    return canSearch(sourceUid);
  }

  /// Check if export is available for the given source
  /// Returns true if the source is connected and at least one study is selected
  bool canExport(String sourceUid) {
    /*final api = OVApi();
    final source = api.sources.findSourceByUid(sourceUid);
    if (source == null) return false;
    return source.isActive && hasSelectedStudies(sourceUid);*/
    return false;
  }

  /// Check if open is available for the given source
  /// Returns true if the source is connected and at least one study is selected
  bool canOpen(String sourceUid) {
    return canExport(sourceUid);
  }

  /// Check if transfer is available for the given source
  /// Returns true if the source is connected and at least one study is selected
  bool canTransfer(String sourceUid) {
    return canExport(sourceUid);
  }
}
*/
