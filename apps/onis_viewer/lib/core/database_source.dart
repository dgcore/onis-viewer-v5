import 'dart:async';
import 'dart:core';

import 'package:flutter/widgets.dart';
import 'package:onis_viewer/core/error_codes.dart';
import 'package:onis_viewer/core/onis_exception.dart';

import '../api/request/async_request.dart';

enum ConnectionStatus {
  loggingIn,
  loggedIn,
  disconnecting,
  disconnected,
}

class DatabaseSourceLoginState extends ChangeNotifier {
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _errorMessage;

  ConnectionStatus get status => _status;
  String? get errorMessage => _errorMessage;

  void setStatus(ConnectionStatus value,
      {bool notify = true, String? errorMessage}) {
    if (_status != value || errorMessage != this.errorMessage) {
      _status = value;
      _errorMessage = errorMessage;
      if (notify) notifyListeners();
    }
  }
}

/// Represents a pending disconnection operation
/*class PendingDisconnection {
  final Completer<void> completer;
  int remainingSubscribers;

  PendingDisconnection(this.completer, this.remainingSubscribers);
}*/

/// Represents a database source with hierarchical structure
/// Each source can have sub-sources and maintains a weak reference to its parent
abstract class DatabaseSource extends ChangeNotifier {
  /// Finalizer to detect when the source is garbage collected
  static final Finalizer<String> _finalizer = Finalizer((uid) {
    debugPrint('🗑️ DatabaseSource DESTRUCTED: uid=$uid');
  });

  /// Unique identifier for this source
  final String uid;

  final String sourceId;

  /// Human-readable name for this source
  String _name;

  /// Weak reference to the parent source (null if root)
  WeakReference<DatabaseSource>? _parentRef;

  /// Weak reference to the source manager
  WeakReference<DatabaseSourceManager>? _managerRef;

  /// Weak reference to the owner source (null if not owned)
  late final WeakReference<DatabaseSource>? _ownerRef;

  /// List of sub-sources
  final List<DatabaseSource> _subSources = [];

  final Map<RequestType, List<AsyncRequest>> _requests = {};

  /// Whether this source is currently active/connected
  //final bool _isActive = false;

  /// Additional metadata for this source
  final Map<String, dynamic> _metadata = {};

  /// Stream controller for disconnection events
  /*static final StreamController<String> _disconnectionController =
      StreamController<String>.broadcast();

  /// Stream for disconnection events (source UID)
  static Stream<String> get onDisconnecting {
    _subscriberCount++;
    debugPrint('New subscriber added. Total subscribers: $_subscriberCount');
    return _disconnectionController.stream;
  }*/

  /// Track the number of active subscribers
  //static int _subscriberCount = 0;

  /// Map to track pending disconnections by source UID
  //static final Map<String, PendingDisconnection> _pendingDisconnections = {};

  /// Subscribe to disconnection events and return the subscription
  /*static StreamSubscription<String> subscribeToDisconnection(
      Function(String) onDisconnecting) {
    _subscriberCount++;
    debugPrint(
        'Subscribed to disconnection events. Total subscribers: $_subscriberCount');
    return _disconnectionController.stream.listen(onDisconnecting);
  }*/

  /// Unsubscribe from disconnection events
  /*static Future<void> unsubscribeToDisconnection(
      StreamSubscription<String>? subscription) async {
    if (subscription != null) {
      await subscription.cancel();
      _subscriberCount = (_subscriberCount - 1).clamp(0, _subscriberCount);
      debugPrint(
          'Unsubscribed from disconnection events. Total subscribers: $_subscriberCount');
    }
  }*/

  /// Emit a disconnection event for this source and return a completer
  /*Future<void> emitDisconnecting() async {
    debugPrint('Emitting disconnection event for source: $uid');

    // Create a pending disconnection
    final completer = Completer<void>();
    final pendingDisconnection =
        PendingDisconnection(completer, _subscriberCount);

    // Store the pending disconnection for this source
    _pendingDisconnections[uid] = pendingDisconnection;

    debugPrint(
        'Waiting for $_subscriberCount subscribers to complete disconnection for source: $uid');

    // Emit the event
    _disconnectionController.add(uid);

    // Wait for this specific disconnection to complete
    await completer.future;
  }*/

  /// Signal that a disconnection subscriber has completed its tasks
  /*static void signalDisconnectionComplete(String sourceUid) {
    debugPrint('Disconnection subscriber completed for source: $sourceUid');

    final pendingDisconnection = _pendingDisconnections[sourceUid];
    if (pendingDisconnection != null &&
        pendingDisconnection.remainingSubscribers > 0) {
      pendingDisconnection.remainingSubscribers--;
      debugPrint(
          'Remaining subscribers for source $sourceUid: ${pendingDisconnection.remainingSubscribers}');

      // If all subscribers have completed, complete the disconnection
      if (pendingDisconnection.remainingSubscribers == 0) {
        if (!pendingDisconnection.completer.isCompleted) {
          pendingDisconnection.completer.complete();
          debugPrint('All subscribers completed for source: $sourceUid');
        }

        // Clean up
        _pendingDisconnections.remove(sourceUid);
      }
    }
  }*/

  /// Public constructor for a database source (without parent)
  /// Parent relationships should be managed by DatabaseSourceManager
  DatabaseSource({
    required this.uid,
    required this.sourceId,
    required String name,
    Map<String, dynamic>? metadata,
  })  : _name = name,
        _parentRef = null {
    if (metadata != null) {
      _metadata.addAll(metadata);
    }
    // Attach finalizer to detect when this source is garbage collected
    _finalizer.attach(this, uid);
    debugPrint('✅ DatabaseSource CREATED: uid=$uid, name=$name');
  }

  /// Get the name of this source
  String get name => _name;

  /// Get the owner source:
  DatabaseSource? get owner => _ownerRef?.target;

  /// Set the owner source:
  void setOwner(DatabaseSource? owner) {
    if (owner == null) {
      _ownerRef = null;
    } else {
      _ownerRef = WeakReference(owner);
    }
  }

  /// Set the name of this source
  set name(String value) {
    if (_name != value) {
      _name = value;
      notifyListeners();
    }
  }

  DatabaseSource? get defaultSource => this;

  void addRequest(AsyncRequest request) {
    debugPrint('---------- Adding request: ${request.requestType}');
    final requestList = _requests.putIfAbsent(request.requestType, () => []);
    requestList.add(request);
  }

  bool removeRequest(AsyncRequest request) {
    debugPrint('---------- Removing request: ${request.requestType}');
    final requestList = _requests[request.requestType];
    if (requestList == null) return false;
    final removed = requestList.remove(request);
    return removed;
  }

  /// Get the parent source (weak reference)
  DatabaseSource? get parent => _parentRef?.target;

  /// Get the source manager (weak reference)
  DatabaseSourceManager? get manager => _managerRef?.target;

  /// Check if this source is actually registered with its manager
  /// This is more reliable than checking the weak reference, as the source
  /// might still be alive due to other references (streams, listeners, etc.)
  bool get isRegistered {
    final mgr = manager;
    if (mgr == null) return false;
    return mgr.findSourceByUid(uid) != null;
  }

  /// Get the list of sub-sources (read-only)
  List<DatabaseSource> get subSources => List.unmodifiable(_subSources);

  /// Get whether this source is active
  /*bool get isActive => _isActive;

  /// Set whether this source is active
  set isActive(bool value) {
    if (_isActive != value) {
      _isActive = value;
      notifyListeners();
    }
  }*/

  /// Get the metadata map
  Map<String, dynamic> get metadata => Map.unmodifiable(_metadata);

  /// Add a sub-source to this source
  /// This method should not be called directly. Use DatabaseSourceManager.addSource() instead.
  void _addSubSourceInternal(DatabaseSource subSource) {
    if (!_subSources.contains(subSource)) {
      _subSources.add(subSource);
      notifyListeners();
    }
  }

  /// Remove a sub-source from this source
  /// This method should not be called directly. Use DatabaseSourceManager.removeSource() instead.
  void _removeSubSourceInternal(DatabaseSource subSource) {
    if (_subSources.remove(subSource)) {
      notifyListeners();
    }
  }

  /// Abstract getter for the login state
  /// Must be implemented by subclasses (like a pure virtual method in C++)
  DatabaseSourceLoginState get loginState;

  /// Optional UI panel for authentication/login when the source is inactive
  /// Default is null; plugins can override to provide a custom panel.
  Widget? buildLoginPanel(BuildContext context, bool useKeyChain) => null;

  /// Optional UI panel for connection/properties (e.g., URL, instance name)
  /// Default is null; plugins can override to provide a custom panel.
  Widget? buildConnectionPanel(BuildContext context) => null;

  // Capability methods for toolbar actions
  // These methods have been moved to DatabaseController for centralized state management

  /// Search method - should be overridden by subclasses
  /// Default implementation does nothing
  //void search() {
  // Default implementation - subclasses should override
  //}

  /// Create an AsyncRequest for the specified request type
  /// Should be overridden by subclasses to provide specific request implementations
  /// Default implementation returns null
  ///
  /// [requestType] - The type of request to create
  /// [data] - Optional JSON data for the request
  /// [files] - Optional map of file paths to field names for file uploads (multipart/form-data)
  AsyncRequest? createRequest(RequestType requestType,
      [Map<String, dynamic>? data, Map<String, String>? files]) {
    // Default implementation - subclasses should override
    return null;
  }

  /// Get the current username for this source (if applicable)
  /// Default implementation returns null
  //String? get currentUsername => null;

  /// Check if this source is currently disconnecting
  /// Default implementation returns false
  /*bool get isDisconnecting => false;

  /// Disconnect from this source
  /// Default implementation returns a completed future
  Future<void> disconnect() async {
    // Default implementation - subclasses should override
  }*/

  /// Get all descendants of this source (recursive)
  List<DatabaseSource> get allDescendants {
    final descendants = <DatabaseSource>[];
    for (final subSource in _subSources) {
      descendants.add(subSource);
      descendants.addAll(subSource.allDescendants);
    }
    return descendants;
  }

  /// Internal: set or clear the parent weak reference
  void _setParentInternal(DatabaseSource? parent) {
    final currentParent = _parentRef?.target;
    if (identical(currentParent, parent)) {
      return;
    }
    _parentRef = parent != null ? WeakReference(parent) : null;
    notifyListeners();
  }

  /// Internal: set or clear the manager weak reference
  void _setManagerInternal(DatabaseSourceManager? manager) {
    final currentManager = _managerRef?.target;
    if (identical(currentManager, manager)) {
      return;
    }
    _managerRef = manager != null ? WeakReference(manager) : null;
  }

  Future<void> disconnect() async {
    if (loginState.status == ConnectionStatus.disconnected ||
        loginState.status == ConnectionStatus.disconnecting) {
      return;
    }
    if (loginState.status != ConnectionStatus.loggedIn) {
      throw OnisException(OnisErrorCodes.logicError, 'Source is not logged in');
    }
    loginState.setStatus(ConnectionStatus.disconnecting);
    await waitForPendingRequests();
    loginState.setStatus(ConnectionStatus.disconnected);
  }

  Future<void> waitForPendingRequests() async {
    const pollInterval = Duration(milliseconds: 10);
    while (_requests.values.any((list) => list.isNotEmpty)) {
      _requests.forEach((type, list) {});
      await Future.delayed(pollInterval);
    }
  }

  /// Track if this source has been disposed
  bool _isDisposed = false;

  /// Check if this source has been disposed
  bool get isDisposed => _isDisposed;

  @override
  void dispose() {
    if (_isDisposed) {
      debugPrint(
          '⚠️ DatabaseSource DISPOSE called again (already disposed): uid=$uid');
      return;
    }
    _isDisposed = true;
    final subSourceCount = _subSources.length;
    final requestCount =
        _requests.values.fold<int>(0, (sum, list) => sum + list.length);
    final hasParent = _parentRef?.target != null;
    final hasManager = _managerRef?.target != null;
    debugPrint(
        '🔌 DatabaseSource DISPOSED: uid=$uid, name=$name, hasListeners=$hasListeners, subSources=$subSourceCount, requests=$requestCount, hasParent=$hasParent, hasManager=$hasManager');
    // Clear internal references to help GC
    _subSources.clear();
    _requests.clear();
    _parentRef = null;
    _managerRef = null;
    super.dispose();
  }
}

/// Manager class for handling database sources
class DatabaseSourceManager extends ChangeNotifier {
  /// Root sources (sources without parents)
  final List<DatabaseSource> _rootSources = [];

  /// All sources indexed by UID for quick lookup
  final Map<String, DatabaseSource> _sourcesByUid = {};

  /// Streams for registration/unregistration events
  final StreamController<DatabaseSource> _sourceRegisteredController =
      StreamController<DatabaseSource>.broadcast();
  final StreamController<DatabaseSource> _sourceUnregisteredController =
      StreamController<DatabaseSource>.broadcast();

  /// Streams for connection/disconnection events
  final StreamController<DatabaseSource> _sourceConnectionController =
      StreamController<DatabaseSource>.broadcast();
  final StreamController<DatabaseSource> _sourceDisconnectionController =
      StreamController<DatabaseSource>.broadcast();

  /// Stream getters
  Stream<DatabaseSource> get onSourceRegistered =>
      _sourceRegisteredController.stream;
  Stream<DatabaseSource> get onSourceUnregistered =>
      _sourceUnregisteredController.stream;
  Stream<DatabaseSource> get onSourceConnection =>
      _sourceConnectionController.stream;
  Stream<DatabaseSource> get onSourceDisconnection =>
      _sourceDisconnectionController.stream;

  /// Get all root sources
  List<DatabaseSource> get rootSources => List.unmodifiable(_rootSources);

  /// Get all sources
  List<DatabaseSource> get allSources =>
      List.unmodifiable(_sourcesByUid.values);

  DatabaseSource? findSourceByUid(String uid) {
    return _sourcesByUid[uid];
  }

  void onSourceConnected(DatabaseSource source) {
    _sourceConnectionController.add(source);
  }

  void onSourceDisconnected(DatabaseSource source) {
    _sourceDisconnectionController.add(source);
  }

  /// Register an existing source with the manager
  /// This is the preferred way to add sources to the manager
  void registerSource(DatabaseSource source, {String? parentUid}) {
    if (_sourcesByUid.containsKey(source.uid)) {
      throw ArgumentError(
          'Source with UID ${source.uid} already exists in manager');
    }
    if (parentUid != null) {
      final parent = _sourcesByUid[parentUid];
      if (parent == null) {
        throw ArgumentError(
            'Parent source with UID $parentUid not found in manager');
      }
      _setParent(source, parent);
    }
    _registerSource(source);
  }

  void removeSource(DatabaseSource source) {
    if (_sourcesByUid.remove(source.uid) == null) return;
    debugPrint(
        '❌ DatabaseSource REMOVED from manager: uid=${source.uid}, name=${source.name}, hasListeners=${source.hasListeners}, subSources=${source.subSources.length}');
    for (final subSource in source.subSources) {
      removeSource(subSource);
    }
    // Detach the source:
    if (source.parent == null) {
      _rootSources.remove(source);
    } else {
      source.parent!._removeSubSourceInternal(source);
    }
    // Clear parent and manager of the removed source
    source._setParentInternal(null);
    source._setManagerInternal(null);
    // Only add to stream if controller is not closed
    if (!_sourceUnregisteredController.isClosed) {
      _sourceUnregisteredController.add(source);
    }
    // Dispose the source to clean up resources
    // Note: This is safe even if the source is still referenced elsewhere,
    // as dispose() is idempotent and ChangeNotifier.dispose() handles cleanup
    source.dispose();
    notifyListeners();

    // Note: There's no way to force GC in Dart - it's non-deterministic.
    // The finalizer will run when GC actually collects the object, which may be delayed.
    // If hasListeners=false in the dispose() log, nothing should be keeping it alive.
    debugPrint(
        '💡 Hint: Source ${source.uid} should be GC\'d when all references are gone. Finalizer will run when GC occurs.');
  }

  /// Internal method to register a source
  void _registerSource(DatabaseSource source) {
    _sourcesByUid[source.uid] = source;
    // Set the manager weak reference
    source._setManagerInternal(this);
    if (source.parent == null) {
      _rootSources.add(source);
    }
    // Only add to stream if controller is not closed
    if (!_sourceRegisteredController.isClosed) {
      _sourceRegisteredController.add(source);
    }
    notifyListeners();
  }

  /// Internal method to set parent relationship
  void _setParent(DatabaseSource source, DatabaseSource parent) {
    // Remove from current parent if any
    if (source.parent != null) {
      source.parent!._removeSubSourceInternal(source);
    } else {
      _rootSources.remove(source);
    }

    // Add to new parent
    source._setParentInternal(parent);
    parent._addSubSourceInternal(source);
  }

  void clear() {
    while (_rootSources.isNotEmpty) {
      removeSource(_rootSources.removeAt(0));
    }
  }

  @override
  void dispose() {
    _sourceRegisteredController.close();
    _sourceUnregisteredController.close();
    super.dispose();
  }

  Future<void> disconnectAll() async {
    while (true) {
      // Find the first connected source in the _sourcesByUid map
      DatabaseSource? firstConnectedSource;
      try {
        firstConnectedSource = _sourcesByUid.values.firstWhere(
          (source) => source.loginState.status == ConnectionStatus.loggedIn,
        );
        await firstConnectedSource.disconnect();
      } catch (e) {
        // No connected source found
        return;
      }
    }
  }
}
