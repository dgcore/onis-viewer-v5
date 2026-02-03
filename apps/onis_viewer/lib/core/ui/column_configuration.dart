/// Generic configuration for a single column in a data grid/table
/// 
/// This class can be used for any data grid in the application.
/// It holds all the necessary information to configure a column's
/// display properties and behavior.
class ColumnConfiguration {
  /// Unique identifier for the column (e.g., 'source', 'patientId', 'name')
  final String id;

  /// Display title for the column header
  final String title;

  /// Whether the column contains numeric data (affects sorting behavior)
  final bool isNumeric;

  /// Width of the column in pixels
  final double width;

  /// Display order of the column (0-based index)
  /// Lower values appear first (left to right)
  final int order;

  ColumnConfiguration({
    required this.id,
    required this.title,
    required this.isNumeric,
    required this.width,
    required this.order,
  });

  /// Create a copy of this configuration with updated values
  ColumnConfiguration copyWith({
    String? id,
    String? title,
    bool? isNumeric,
    double? width,
    int? order,
  }) {
    return ColumnConfiguration(
      id: id ?? this.id,
      title: title ?? this.title,
      isNumeric: isNumeric ?? this.isNumeric,
      width: width ?? this.width,
      order: order ?? this.order,
    );
  }

  /// Convert to JSON for storage/configuration persistence
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isNumeric': isNumeric,
        'width': width,
        'order': order,
      };

  /// Create from JSON (for loading from configuration)
  factory ColumnConfiguration.fromJson(Map<String, dynamic> json) {
    return ColumnConfiguration(
      id: json['id'] as String,
      title: json['title'] as String? ?? json['id'] as String,
      isNumeric: json['isNumeric'] as bool? ?? false,
      width: (json['width'] as num?)?.toDouble() ?? 120.0,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  String toString() =>
      'ColumnConfiguration(id: $id, title: $title, isNumeric: $isNumeric, width: $width, order: $order)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColumnConfiguration &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          isNumeric == other.isNumeric &&
          width == other.width &&
          order == other.order;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      isNumeric.hashCode ^
      width.hashCode ^
      order.hashCode;
}

/// Collection of column configurations for a data grid
/// 
/// This class manages a set of column configurations and provides
/// utilities for accessing and manipulating them. It can be used
/// for any data grid in the application.
class ColumnConfigurationList {
  final List<ColumnConfiguration> columns;

  ColumnConfigurationList({required this.columns});

  /// Get columns sorted by their display order
  List<ColumnConfiguration> get sortedColumns {
    final sorted = List<ColumnConfiguration>.from(columns);
    sorted.sort((a, b) => a.order.compareTo(b.order));
    return sorted;
  }

  /// Get a column configuration by its id
  ColumnConfiguration? getById(String id) {
    try {
      return columns.firstWhere((col) => col.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get the display order of a column by its id
  int? getOrderById(String id) => getById(id)?.order;

  /// Get the width of a column by its id
  double? getWidthById(String id) => getById(id)?.width;

  /// Update a column's configuration
  /// Returns a new ColumnConfigurationList with the updated column
  ColumnConfigurationList updateColumn(ColumnConfiguration updatedColumn) {
    final updatedColumns = columns.map((col) {
      return col.id == updatedColumn.id ? updatedColumn : col;
    }).toList();
    return ColumnConfigurationList(columns: updatedColumns);
  }

  /// Update multiple columns at once
  /// Returns a new ColumnConfigurationList with the updated columns
  ColumnConfigurationList updateColumns(List<ColumnConfiguration> updatedColumns) {
    final columnMap = <String, ColumnConfiguration>{};
    for (final col in columns) {
      columnMap[col.id] = col;
    }
    for (final updated in updatedColumns) {
      columnMap[updated.id] = updated;
    }
    return ColumnConfigurationList(columns: columnMap.values.toList());
  }

  /// Convert to JSON for storage/configuration persistence
  List<Map<String, dynamic>> toJson() =>
      columns.map((col) => col.toJson()).toList();

  /// Create from JSON (for loading from configuration)
  factory ColumnConfigurationList.fromJson(List<dynamic> json) {
    return ColumnConfigurationList(
      columns: json
          .map((item) => ColumnConfiguration.fromJson(
              item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Create an empty configuration list
  factory ColumnConfigurationList.empty() {
    return ColumnConfigurationList(columns: []);
  }
}

