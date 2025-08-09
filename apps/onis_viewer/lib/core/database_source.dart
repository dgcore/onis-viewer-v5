import 'dart:core';

import 'package:flutter/foundation.dart';

/// Represents a database source with hierarchical structure
/// Each source can have sub-sources and maintains a weak reference to its parent
class DatabaseSource extends ChangeNotifier {
  /// Unique identifier for this source
  final String uid;

  /// Human-readable name for this source
  String _name;

  /// Weak reference to the parent source (null if root)
  final WeakReference<DatabaseSource>? _parentRef;

  /// List of sub-sources
  final List<DatabaseSource> _subSources = [];

  /// Whether this source is currently active/connected
  bool _isActive = false;

  /// Additional metadata for this source
  final Map<String, dynamic> _metadata = {};

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

  /// Remove a sub-source by its UID
  /*void removeSubSourceByUid(String uid) {
    _subSources.removeWhere((source) => source.uid == uid);
    notifyListeners();
  }*/

  /// Find a sub-source by its UID
  /*DatabaseSource? findSubSourceByUid(String uid) {
    return _subSources.where((source) => source.uid == uid).firstOrNull;
  }*/

  /// Add metadata to this source
  /*void setMetadata(String key, dynamic value) {
    _metadata[key] = value;
    notifyListeners();
  }

  /// Get metadata value by key
  dynamic getMetadata(String key) {
    return _metadata[key];
  }

  /// Remove metadata by key
  void removeMetadata(String key) {
    if (_metadata.remove(key) != null) {
      notifyListeners();
    }
  }*/

  /// Get the root source (traverse up the hierarchy)
  /*DatabaseSource get root {
    DatabaseSource current = this;
    while (current.parent != null) {
      current = current.parent!;
    }
    return current;
  }

  /// Get the depth of this source in the hierarchy (0 for root)
  int get depth {
    int depth = 0;
    DatabaseSource? current = parent;
    while (current != null) {
      depth++;
      current = current.parent;
    }
    return depth;
  }

  /// Get the full path of this source (from root to this source)
  List<DatabaseSource> get path {
    final path = <DatabaseSource>[];
    DatabaseSource? current = this;
    while (current != null) {
      path.insert(0, current);
      current = current.parent;
    }
    return path;
  }

  /// Get the full path as a string (using names)
  String get pathString {
    return path.map((source) => source.name).join(' > ');
  }

  /// Check if this source is a descendant of the given source
  bool isDescendantOf(DatabaseSource ancestor) {
    DatabaseSource? current = parent;
    while (current != null) {
      if (current == ancestor) {
        return true;
      }
      current = current.parent;
    }
    return false;
  }

  /// Check if this source is an ancestor of the given source
  bool isAncestorOf(DatabaseSource descendant) {
    return descendant.isDescendantOf(this);
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
      }

      notifyListeners();
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
