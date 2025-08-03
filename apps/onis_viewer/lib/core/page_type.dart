import 'package:flutter/material.dart';

/// Represents a page type in the ONIS Viewer application.
/// This class-based approach allows for dynamic plugin-based page creation.
class PageType {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color? color;
  final Map<String, dynamic> metadata;
  final Widget Function(PageType)? pageCreator;

  const PageType({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.color,
    this.metadata = const {},
    this.pageCreator,
  });

  /// Get all registered page types (will be populated by plugins)
  static List<PageType> get registeredTypes => _registeredTypes;
  static final List<PageType> _registeredTypes = [];

  /// Register a page type (called by plugins)
  static void register(PageType pageType) {
    if (!_registeredTypes.any((type) => type.id == pageType.id)) {
      _registeredTypes.add(pageType);
    }
  }

  /// Unregister a page type
  static void unregister(String pageTypeId) {
    _registeredTypes.removeWhere((type) => type.id == pageTypeId);
  }

  /// Find page type by ID
  static PageType? fromId(String id) {
    return _registeredTypes.where((type) => type.id == id).firstOrNull;
  }

  /// Clear all registered page types
  static void clear() {
    _registeredTypes.clear();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PageType && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PageType(id: $id, name: $name)';

  /// Create a copy with modified properties
  PageType copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    Color? color,
    Map<String, dynamic>? metadata,
    Widget Function(PageType)? pageCreator,
  }) {
    return PageType(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      metadata: metadata ?? this.metadata,
      pageCreator: pageCreator ?? this.pageCreator,
    );
  }
}
