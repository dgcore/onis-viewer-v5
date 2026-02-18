import 'dart:async';

import 'package:flutter/material.dart';
import 'package:onis_viewer/api/request/async_request.dart';
import 'package:onis_viewer/core/database_source.dart';
import 'package:onis_viewer/core/error_codes.dart';
import 'package:onis_viewer/core/models/database/filter.dart';
import 'package:onis_viewer/core/models/database/patient.dart' as database;
import 'package:onis_viewer/core/models/database/study.dart' as database;
import 'package:onis_viewer/core/onis_exception.dart';
import 'package:onis_viewer/core/responses/find_study_response.dart';
import 'package:onis_viewer/plugins/database/public/source_controller_interface.dart';
import 'package:onis_viewer/plugins/database/ui/database_source_bar.dart';
import 'package:onis_viewer/plugins/database/ui/retrieve_series.dart';

class SourceState {
  SourceState();
  List<({String sourceUid, int status})> sourceStatuses = [];
  List<({database.Patient patient, database.Study study})> studies = [];
  List<({database.Patient patient, database.Study study})> selectedStudies = [];
  double horizontalScrollPosition = 0.0;
  double verticalScrollPosition = 0.0;
  void reset() {
    sourceStatuses.clear();
    studies.clear();
    selectedStudies.clear();
    horizontalScrollPosition = 0.0;
    verticalScrollPosition = 0.0;
  }
}

class SourceController extends ISourceController {
  late final DatabaseSourceManager _databaseSourceManager;
  final Map<String, SourceState> _sourceStates = {};
  DatabaseSource? _selectedSource;

  /// Stream subscriptions for source registration events
  StreamSubscription<DatabaseSource>? _sourceRegisteredSubscription;
  StreamSubscription<DatabaseSource>? _sourceUnregisteredSubscription;
  StreamSubscription<DatabaseSource>? _sourceConnectionSubscription;
  StreamSubscription<DatabaseSource>? _sourceDisconnectionSubscription;

  /// Constructor
  SourceController();

  /// Initialize the controller
  Future<void> initialize() async {
    _databaseSourceManager = DatabaseSourceManager();

    // Listen to ChangeNotifier notifications from the manager
    _databaseSourceManager.addListener(_onManagerChanged);

    // Listen to stream events for source registration/unregistration
    _sourceRegisteredSubscription =
        _databaseSourceManager.onSourceRegistered.listen(_onSourceRegistered);
    _sourceUnregisteredSubscription = _databaseSourceManager
        .onSourceUnregistered
        .listen(_onSourceUnregistered);

    _sourceConnectionSubscription =
        _databaseSourceManager.onSourceConnection.listen(_onSourceConnection);
    _sourceDisconnectionSubscription = _databaseSourceManager
        .onSourceDisconnection
        .listen(_onSourceDisconnection);

    // Register the existing sources:
    final sources = _databaseSourceManager.allSources;
    for (final source in sources) {
      _onSourceRegistered(source);
    }
  }

  /// Called when DatabaseSourceManager notifies listeners
  /// This allows SourceController to react to manager changes and forward notifications
  void _onManagerChanged() {
    // Forward the notification to SourceController's listeners
    // This ensures that widgets listening to SourceController are notified
    // when the underlying DatabaseSourceManager changes
    notifyListeners();

    // You can also handle specific logic here, such as:
    // - Updating selected source if it was removed
    // - Clearing state for removed sources
    // - etc.
  }

  @override
  void dispose() {
    // Remove listener from manager before disposing
    _databaseSourceManager.removeListener(_onManagerChanged);
    // Cancel stream subscriptions (these are synchronous operations)
    _sourceRegisteredSubscription?.cancel();
    _sourceUnregisteredSubscription?.cancel();
    super.dispose();
  }

  @override
  void notifyUpdate() {
    notifyListeners();
  }

  void _onSourceRegistered(DatabaseSource source) {
    _sourceStates[source.uid] = SourceState();
  }

  void _onSourceUnregistered(DatabaseSource source) {
    _sourceStates.remove(source.uid);
    if (_selectedSource == source) {
      _selectedSource = null;
    }
  }

  void _onSourceConnection(DatabaseSource source) {
    _selectedSource = source.defaultSource;
    expandSourceNode(source.uid, expand: true, expandChildren: true);
  }

  void _onSourceDisconnection(DatabaseSource source) {
    _selectedSource ??= source;
  }

  @override
  DatabaseSourceManager get sources => _databaseSourceManager;

  @override
  DatabaseSource? get selectedSource => _selectedSource;

  /*@override
  DatabaseSourceLoginState? getLoginState(String sourceUid) {
    final sourceState = _sourceStates[sourceUid];
    return sourceState?.loginState;
  }*/

  @override
  int get totalStudyCount {
    //return _studiesBySource.values
    //    .fold(0, (sum, studies) => sum + studies.length);
    return 0;
  }

  @override
  void selectSourceByUid(String sourceUid) {
    final source = _databaseSourceManager.findSourceByUid(sourceUid);
    if (source == null) {
      _selectedSource = null;
    } else {
      _selectedSource = source;
    }
    notifyListeners();
  }

  @override
  void expandSourceNode(String sourceUid,
      {bool expand = true, bool expandChildren = false}) {
    if (expand) {
      DatabaseSourceBar.expandNode(sourceUid, expandChildren: expandChildren);
    } else {
      DatabaseSourceBar.collapseNode(sourceUid);
    }
  }

  /*void executeRequest(String uid, AsyncRequest request) {
    final sourceState = _sourceStates[uid];
    if (sourceState != null) {
      // Ensure the list exists for this request type
      sourceState.pendingRequests.putIfAbsent(
        request.requestType,
        () => <AsyncRequest>[],
      );
      sourceState.pendingRequests[request.requestType]!.add(request);
      request.send();
    }
  }*/

  /// Check if search is available for the given source
  /// Returns true if the source is connected
  @override
  bool canSearch(String sourceUid) {
    final source = _databaseSourceManager.findSourceByUid(sourceUid);
    return source?.loginState.status == ConnectionStatus.loggedIn;
  }

  /// Check if import is available for the given source
  /// Returns true if the source is connected
  @override
  bool canImport(String sourceUid) {
    return canSearch(sourceUid);
  }

  /// Check if export is available for the given source
  /// Returns true if the source is connected and at least one study is selected
  @override
  bool canExport(String sourceUid) {
    SourceState? sourceState = _sourceStates[sourceUid];
    if (sourceState == null) return false;
    return sourceState.selectedStudies.isNotEmpty;
  }

  /// Check if open is available for the given source
  /// Returns true if the source is connected and at least one study is selected
  @override
  bool canOpen(String sourceUid) {
    return canExport(sourceUid);
  }

  /// Check if transfer is available for the given source
  /// Returns true if the source is connected and at least one study is selected
  @override
  bool canTransfer(String sourceUid) {
    return canExport(sourceUid);
  }

  @override
  Future<FindPatientStudyResponse> findStudies(String sourceUid,
      {DBFilters? filters, bool withSeries = false}) async {
    final source = _databaseSourceManager.findSourceByUid(sourceUid);
    if (source == null) {
      return FindPatientStudyResponse(
          source: source!, status: OnisErrorCodes.logicError, sources: []);
    }
    Map<String, dynamic> data = {};
    if (filters != null) {
      data['filters'] = filters.toJson();
    }
    if (withSeries) {
      data['with-series'] = true;
    }
    AsyncRequest? request = source.createRequest(RequestType.findStudies, data);
    try {
      AsyncResponse? response = await request?.send();
      if (response != null && response.data != null) {
        return FindPatientStudyResponse.fromJson(source, response.data!);
      } else {
        return FindPatientStudyResponse(
            source: source,
            status: OnisErrorCodes.invalidResponse,
            sources: []);
      }
    } on OnisException catch (e) {
      return FindPatientStudyResponse(
          source: source, status: e.code, sources: []);
    } catch (e) {
      return FindPatientStudyResponse(
          source: source, status: OnisErrorCodes.unknown, sources: []);
    }
  }

  @override
  void clearStudies(String sourceUid) {
    SourceState? sourceState = _sourceStates[sourceUid];
    if (sourceState != null) {
      sourceState.reset();
    }
  }

  @override
  void setStudies(FindPatientStudyResponse response) {
    SourceState? sourceState = _sourceStates[response.source.uid];
    if (sourceState != null) {
      sourceState.reset();
      if (response.status == OnisErrorCodes.none) {
        for (FindPatientStudySourceResponse sourceResponse
            in response.sources) {
          sourceState.sourceStatuses.add((
            sourceUid: sourceResponse.source.uid,
            status: sourceResponse.status,
          ));
          sourceState.studies.addAll(sourceResponse.studies);
        }
      } else {
        sourceState.sourceStatuses.add((
          sourceUid: response.source.uid,
          status: response.status,
        ));
      }
      notifyListeners();
    }
  }

  /// Import a DICOM file to the specified source
  ///
  /// [sourceUid] - The unique identifier of the source
  /// [filePath] - The path to the file to import
  ///
  /// The file will be uploaded in binary mode using multipart/form-data
  @override
  Future<Map<String, dynamic>?> importDicomFile(
      String sourceUid, String filePath) async {
    final source = _databaseSourceManager.findSourceByUid(sourceUid);
    if (source == null) {
      return null;
    }

    // Create request with file upload (multipart/form-data)
    // The file will be sent as a binary stream, efficient for large files
    final files = <String, String>{
      filePath: 'file', // Field name for the file on the server
    };

    final data = <String, dynamic>{
      'source': "ab827b22-a4b9-44a4-96d8-28c6d2a29884", //source.uid,
      'type': 0,
    };

    final request = source.createRequest(RequestType.import, data, files);
    if (request == null) {
      return null;
    }

    try {
      final response = await request.send();
      if (response.isSuccess && response.data != null) {
        return response.data;
      } else {
        return null;
      }
    } catch (e) {
      // Handle any errors during file upload
      return null;
    }
  }

  @override
  void openSelectedStudies(String sourceUid, BuildContext context) {
    ({
      List<database.Patient> patients,
      ({database.Patient patient, database.Study study})? primary
    }) items = _getItemsToOpen(sourceUid);

    if (items.patients.isNotEmpty) {
      // Show retrieve series dialog with patients and primary study
      RetrieveSeriesDialog.show(
        context,
        patients: items.patients,
        primary: items.primary,
      ).then((cancelled) {
        // Dialog closed - proceed with opening patients if not cancelled
        if (cancelled != true) {
          //openPatients(items.patients, items.primary, null, null);
        }
      });
    }
  }

  @override
  List<({String sourceUid, int status})> getSourceStatuses(String sourceUid) {
    SourceState? sourceState = _sourceStates[sourceUid];
    final statuses = sourceState?.sourceStatuses ?? [];
    return List.unmodifiable(statuses);
  }

  @override
  List<({database.Patient patient, database.Study study})> getStudiesForSource(
          String sourceUid) =>
      _sourceStates[sourceUid]?.studies ?? [];

  @override
  List<({database.Patient patient, database.Study study})>
      getSelectedStudiesForSource(String sourceUid) =>
          _sourceStates[sourceUid]?.selectedStudies ?? [];

  @override
  ({double horizontal, double vertical}) getScrollPositionsForSource(
      String sourceUid) {
    SourceState? sourceState = _sourceStates[sourceUid];
    return (
      horizontal: sourceState?.horizontalScrollPosition ?? 0.0,
      vertical: sourceState?.verticalScrollPosition ?? 0.0
    );
  }

  @override
  void saveScrollPositionsForSource(
      String sourceUid, double horizontalPosition, double verticalPosition) {
    SourceState? sourceState = _sourceStates[sourceUid];
    if (sourceState != null) {
      sourceState.horizontalScrollPosition = horizontalPosition;
      sourceState.verticalScrollPosition = verticalPosition;
    }
  }

  ({
    List<database.Patient> patients,
    ({database.Patient patient, database.Study study})? primary
  }) _getItemsToOpen(String sourceUid) {
    final selectedStudies = getSelectedStudiesForSource(sourceUid);
    if (selectedStudies.isEmpty) {
      return (patients: [], primary: null);
    }
    // Use a Set to track unique patient identifiers (id, sourceUid, pid)
    final seenPatientKeys = <String>{};
    final patients = <database.Patient>[];
    for (final item in selectedStudies) {
      // Create a unique key for the patient
      final patientKey =
          '${item.patient.id}|${item.patient.sourceUid}|${item.patient.pid}';
      // Only add if we haven't seen this patient before
      if (!seenPatientKeys.contains(patientKey)) {
        seenPatientKeys.add(patientKey);
        patients.add(item.patient);
      }
    }
    return (patients: patients, primary: selectedStudies.first);
  }
}
