import 'dart:async';

import 'package:onis_viewer/core/database_source.dart';
import 'package:onis_viewer/core/models/study.dart';
import 'package:onis_viewer/plugins/database/public/source_controller_interface.dart';
import 'package:onis_viewer/plugins/database/ui/database_source_bar.dart';

class SourceState {
  SourceState(DatabaseSource source) {
    //loginState = source.createLoginState();
  }
  //DatabaseSourceLoginState? loginState;
  bool isConnected = false;
  List<Study> studies = [];
  List<Study> selectedStudies = [];
  double scrollPosition = 0.0;
  //Map<RequestType, List<AsyncRequest>> pendingRequests = {};
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

  void _onSourceRegistered(DatabaseSource source) {
    _sourceStates[source.uid] = SourceState(source);
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
    /*final api = OVApi();
    final source = api.sources.findSourceByUid(sourceUid);
    if (source == null) return false;
    return source.isActive && hasSelectedStudies(sourceUid);*/
    return false;
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
}
