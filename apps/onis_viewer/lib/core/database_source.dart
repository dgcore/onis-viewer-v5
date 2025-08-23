import 'dart:async';
import 'dart:core';

import 'package:flutter/widgets.dart';

import '../api/request/async_request.dart';

// Note: SiteSource import removed to avoid circular dependency
// We'll use runtime type checking instead

/// Represents a pending disconnection operation
class PendingDisconnection {
  final Completer<void> completer;
  int remainingSubscribers;

  PendingDisconnection(this.completer, this.remainingSubscribers);
}

/// Represents a database source with hierarchical structure
/// Each source can have sub-sources and maintains a weak reference to its parent
class DatabaseSource extends ChangeNotifier {
  /// Unique identifier for this source
  final String uid;

  /// Human-readable name for this source
  String _name;

  /// Weak reference to the parent source (null if root)
  WeakReference<DatabaseSource>? _parentRef;

  /// List of sub-sources
  final List<DatabaseSource> _subSources = [];

  /// Whether this source is currently active/connected
  bool _isActive = false;

  /// Additional metadata for this source
  final Map<String, dynamic> _metadata = {};

  /// Stream controller for disconnection events
  static final StreamController<String> _disconnectionController =
      StreamController<String>.broadcast();

  /// Stream for disconnection events (source UID)
  static Stream<String> get onDisconnecting {
    _subscriberCount++;
    debugPrint('New subscriber added. Total subscribers: $_subscriberCount');
    return _disconnectionController.stream;
  }

  /// Track the number of active subscribers
  static int _subscriberCount = 0;

  /// Map to track pending disconnections by source UID
  static final Map<String, PendingDisconnection> _pendingDisconnections = {};

  /// Subscribe to disconnection events and return the subscription
  static StreamSubscription<String> subscribeToDisconnection(
      Function(String) onDisconnecting) {
    _subscriberCount++;
    debugPrint(
        'Subscribed to disconnection events. Total subscribers: $_subscriberCount');
    return _disconnectionController.stream.listen(onDisconnecting);
  }

  /// Unsubscribe from disconnection events
  static Future<void> unsubscribeToDisconnection(
      StreamSubscription<String>? subscription) async {
    if (subscription != null) {
      await subscription.cancel();
      _subscriberCount = (_subscriberCount - 1).clamp(0, _subscriberCount);
      debugPrint(
          'Unsubscribed from disconnection events. Total subscribers: $_subscriberCount');
    }
  }

  /// Emit a disconnection event for this source and return a completer
  Future<void> emitDisconnecting() async {
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
  }

  /// Signal that a disconnection subscriber has completed its tasks
  static void signalDisconnectionComplete(String sourceUid) {
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
  }

  /// Public constructor for a database source (without parent)
  /// Parent relationships should be managed by DatabaseSourceManager
  DatabaseSource({
    required this.uid,
    required String name,
    Map<String, dynamic>? metadata,
  })  : _name = name,
        _parentRef = null {
    if (metadata != null) {
      _metadata.addAll(metadata);
    }
  }

  /// Internal constructor for creating sources with parent (used by manager)
  /*DatabaseSource._withParent({
    required this.uid,
    required String name,
    required DatabaseSource parent,
    Map<String, dynamic>? metadata,
  })  : _name = name,
        _parentRef = WeakReference(parent) {
    if (metadata != null) {
      _metadata.addAll(metadata);
    }
  }*/

  /// Get the name of this source
  String get name => _name;

  /// Set the name of this source
  set name(String value) {
    if (_name != value) {
      _name = value;
      notifyListeners();
    }
  }

  /// Get the parent source (weak reference)
  DatabaseSource? get parent => _parentRef?.target;

  /// Get the list of sub-sources (read-only)
  List<DatabaseSource> get subSources => List.unmodifiable(_subSources);

  /// Get whether this source is active
  bool get isActive => _isActive;

  /// Set whether this source is active
  set isActive(bool value) {
    if (_isActive != value) {
      _isActive = value;
      notifyListeners();
    }
  }

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

  /// Optional UI panel for authentication/login when the source is inactive
  /// Default is null; plugins can override to provide a custom panel.
  /// When provided and [isActive] is false, the application may render this
  /// panel instead of the normal content area.
  Widget? buildLoginPanel(BuildContext context) => null;

  /// Optional UI panel for connection/properties (e.g., URL, instance name)
  /// Default is null; plugins can override to provide a custom panel.
  Widget? buildConnectionPanel(BuildContext context) => null;

  // Capability methods for toolbar actions
  // These methods should be overridden by subclasses to provide specific capabilities

  /// Check if the source supports opening databases
  /// Default implementation returns false
  bool get canOpen => false;

  /// Check if the source supports importing data
  /// Default implementation returns false
  bool get canImport => false;

  /// Check if the source supports exporting data
  /// Default implementation returns false
  bool get canExport => false;

  /// Check if the source supports transferring data
  /// Default implementation returns false
  bool get canTransfer => false;

  /// Check if the source supports searching
  /// Default implementation returns true when the source is active/connected
  bool get canSearch => isActive;

  /// Search method - should be overridden by subclasses
  /// Default implementation does nothing
  void search() {
    // Default implementation - subclasses should override
  }

  /// Create an AsyncRequest for the specified request type
  /// Should be overridden by subclasses to provide specific request implementations
  /// Default implementation returns null
  AsyncRequest? createRequest(RequestType requestType,
      [Map<String, dynamic>? data]) {
    // Default implementation - subclasses should override
    return null;
  }

  /// Get the current username for this source (if applicable)
  /// Default implementation returns null
  String? get currentUsername => null;

  /// Check if this source is currently disconnecting
  /// Default implementation returns false
  bool get isDisconnecting => false;

  /// Disconnect from this source
  /// Default implementation returns a completed future
  Future<void> disconnect() async {
    // Default implementation - subclasses should override
  }

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

  /// Get all sources in the subtree (including this source)
  /*List<DatabaseSource> get subtree {
    final sources = <DatabaseSource>[this];
    sources.addAll(allDescendants);
    return sources;
  }

  /// Find a source by UID in the entire subtree
  DatabaseSource? findInSubtree(String uid) {
    if (this.uid == uid) {
      return this;
    }
    for (final subSource in _subSources) {
      final found = subSource.findInSubtree(uid);
      if (found != null) {
        return found;
      }
    }
    return null;
  }*/

  /*@override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DatabaseSource && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() {
    return 'DatabaseSource(uid: $uid, name: $name, parent: ${parent?.uid}, subSources: ${_subSources.length})';
  }*/
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

  /// Stream getters
  Stream<DatabaseSource> get onSourceRegistered =>
      _sourceRegisteredController.stream;
  Stream<DatabaseSource> get onSourceUnregistered =>
      _sourceUnregisteredController.stream;

  /// Get all root sources
  List<DatabaseSource> get rootSources => List.unmodifiable(_rootSources);

  /// Get all sources
  List<DatabaseSource> get allSources =>
      List.unmodifiable(_sourcesByUid.values);

  /// Create a basic source (legacy method for backward compatibility)
  /// This creates a DatabaseSource with optional parent
  /*DatabaseSource createSource({
    required String uid,
    required String name,
    String? parentUid,
    Map<String, dynamic>? metadata,
  }) {
    if (_sourcesByUid.containsKey(uid)) {
      throw ArgumentError('Source with UID $uid already exists');
    }

    DatabaseSource? parent;
    if (parentUid != null) {
      parent = _sourcesByUid[parentUid];
      if (parent == null) {
        throw ArgumentError(
            'Parent source with UID $parentUid not found in manager');
      }
    }

    final source = parent != null
        ? DatabaseSource._withParent(
            uid: uid,
            name: name,
            parent: parent,
            metadata: metadata,
          )
        : DatabaseSource(
            uid: uid,
            name: name,
            metadata: metadata,
          );

    _registerSource(source);
    return source;
  }*/

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

  /// Set the parent of a source (manager-controlled)
  /*void setParent(DatabaseSource source, String parentUid) {
    final parent = _sourcesByUid[parentUid];
    if (parent == null) {
      throw ArgumentError(
          'Parent source with UID $parentUid not found in manager');
    }
    _setParent(source, parent);
  }

  /// Remove the parent of a source (make it a root source)
  void removeParent(DatabaseSource source) {
    if (source.parent != null) {
      source.parent!._removeSubSourceInternal(source);
      _rootSources.add(source);
      notifyListeners();
    }
  }*/

  /// Internal method to register a source
  void _registerSource(DatabaseSource source) {
    _sourcesByUid[source.uid] = source;
    if (source.parent == null) {
      _rootSources.add(source);
    }
    _sourceRegisteredController.add(source);
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

  /// Remove a source from the manager
  void removeSource(DatabaseSource source) {
    if (_sourcesByUid.remove(source.uid) != null) {
      if (source.parent == null) {
        _rootSources.remove(source);
      } else {
        // Use internal method to maintain relationship integrity
        source.parent!._removeSubSourceInternal(source);
      }

      // Remove all descendants as well
      for (final descendant in source.allDescendants) {
        _sourcesByUid.remove(descendant.uid);
        descendant._setParentInternal(null);
      }

      // Clear parent of the removed source
      source._setParentInternal(null);

      _sourceUnregisteredController.add(source);
      notifyListeners();
    }
  }

  /// Remove a source from the manager, disconnecting it first if needed
  /// Returns a Future that completes when the source is fully removed
  Future<void> removeSourceWithDisconnect(DatabaseSource source) async {
    // Check if source needs disconnection
    if (source.isActive) {
      try {
        // Use dynamic casting to avoid circular dependency
        final dynamic dynamicSource = source;
        if (dynamicSource.disconnect != null) {
          await dynamicSource.disconnect();
        } else {
          debugPrint(
              'Disconnect not implemented for source type ${source.runtimeType}');
        }
      } catch (e) {
        // Log error but continue with removal
        debugPrint('Failed to disconnect source ${source.uid}: $e');
      }
    }

    // Now remove the source
    removeSource(source);
  }

  /// Remove a source by UID, disconnecting it first if needed
  /// Returns a Future that completes when the source is fully removed
  Future<void> removeSourceByUidWithDisconnect(String uid) async {
    final source = _sourcesByUid[uid];
    if (source != null) {
      await removeSourceWithDisconnect(source);
    }
  }

  /// Remove a source by UID
  /*void removeSourceByUid(String uid) {
    final source = _sourcesByUid[uid];
    if (source != null) {
      removeSource(source);
    }
  }*/

  /// Find a source by UID
  /*DatabaseSource? findSourceByUid(String uid) {
    return _sourcesByUid[uid];
  }

  /// Get all active sources
  List<DatabaseSource> get activeSources {
    return _sourcesByUid.values.where((source) => source.isActive).toList();
  }

  /// Get all inactive sources
  List<DatabaseSource> get inactiveSources {
    return _sourcesByUid.values.where((source) => !source.isActive).toList();
  }*/

  /// Clear all sources
  void clear() {
    _rootSources.clear();
    _sourcesByUid.clear();
    notifyListeners();
  }

  /// Clean exit: disconnect all active sources before clearing
  /// Returns a Future that completes when all sources are properly disconnected
  Future<void> cleanExit() async {
    final activeSources =
        _sourcesByUid.values.where((source) => source.isActive).toList();

    // Disconnect all active sources concurrently
    final disconnectFutures = activeSources.map((source) async {
      try {
        // Use dynamic casting to avoid circular dependency
        final dynamic dynamicSource = source;
        if (dynamicSource.disconnect != null) {
          await dynamicSource.disconnect();
        } else {
          debugPrint(
              'Disconnect not implemented for source type ${source.runtimeType}');
        }
      } catch (e) {
        debugPrint(
            'Failed to disconnect source ${source.uid} during clean exit: $e');
      }
    });

    // Wait for all disconnections to complete
    await Future.wait(disconnectFutures);

    // Now clear all sources
    clear();
  }

  @override
  void dispose() {
    _sourceRegisteredController.close();
    _sourceUnregisteredController.close();
    super.dispose();
  }

  /// Get sources by metadata value
  /*List<DatabaseSource> getSourcesByMetadata(String key, dynamic value) {
    return _sourcesByUid.values
        .where((source) => source.getMetadata(key) == value)
        .toList();
  }

  @override
  String toString() {
    return 'DatabaseSourceManager(rootSources: ${_rootSources.length}, totalSources: ${_sourcesByUid.length})';
  }*/
}
