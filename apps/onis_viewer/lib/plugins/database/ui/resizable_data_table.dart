import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:onis_viewer/core/models/database/patient.dart' as database;
import 'package:onis_viewer/core/models/database/study.dart' as database;
import 'package:onis_viewer/core/responses/find_study_response.dart';

import '../../../core/constants.dart';
import '../../../core/ui/column_configuration.dart';
import 'database_table_column_config.dart';

/// A resizable data table that allows column width adjustment
class ResizableDataTable extends StatefulWidget {
  final List<FindPatientStudyItem> studies;
  final List<FindPatientStudyItem> selectedStudies;
  final VoidCallback? onStudySelectionChanged;
  /*final ValueChanged<({database.Patient patient, database.Study study})>?
      onStudySelected;
  final ValueChanged<List<({database.Patient patient, database.Study study})>>?
      onStudiesSelected;*/
  final int? sortColumnIndex;
  final bool sortAscending;
  final ValueChanged<int?>? onSort;
  final ({double horizontal, double vertical}) initialScrollPositions;
  final ValueChanged<({double horizontal, double vertical})>?
      onScrollPositionChanged;

  const ResizableDataTable({
    super.key,
    required this.studies,
    required this.selectedStudies,
    this.onStudySelectionChanged,
    //this.onStudySelected,
//    this.onStudiesSelected,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
    this.initialScrollPositions = const (horizontal: 0.0, vertical: 0.0),
    this.onScrollPositionChanged,
  });

  @override
  State<ResizableDataTable> createState() => _ResizableDataTableState();
}

class _ResizableDataTableState extends State<ResizableDataTable>
    with WidgetsBindingObserver {
  // Column configuration
  late ColumnConfigurationList _columnConfig;

  // Derived state from column configuration
  List<ColumnConfiguration> get _sortedColumns => _columnConfig.sortedColumns;
  int get _columnCount => _sortedColumns.length;

  // Column dragging state
  late List<bool> _isDragging;
  final double _minColumnWidth = 80.0;
  final double _maxColumnWidth = 400.0;

  // Column reordering state (stores column IDs in display order)
  late List<String> _columnOrder;
  int? _draggedColumnIndex;
  int? _dropTargetIndex;
  bool _isDraggingColumn = false;
  Offset? _dragOffset;
  final GlobalKey _stackKey = GlobalKey();

  // Filter controllers (one per column)
  late List<TextEditingController> _filterControllers;

  // Selection state
  FindPatientStudyItem?
      _lastSelectedStudy; // Track last selected study for range selection
  late ScrollController _scrollController;
  late ScrollController _verticalScrollController;

  @override
  void initState() {
    super.initState();

    // Initialize column configuration with defaults
    _columnConfig = DatabaseTableColumnConfig.createDefault();
    _columnOrder = _sortedColumns.map((col) => col.id).toList();
    _isDragging = List.filled(_columnCount, false);
    _filterControllers = List.generate(
      _columnCount,
      (index) => TextEditingController(),
    );

    _scrollController = ScrollController(
        initialScrollOffset: widget.initialScrollPositions.horizontal);
    _scrollController.addListener(_onScrollChanged);

    _verticalScrollController = ScrollController(
        initialScrollOffset: widget.initialScrollPositions.vertical);
    _verticalScrollController.addListener(_onScrollChanged);

    // Add listeners to filter controllers
    for (final controller in _filterControllers) {
      controller.addListener(_onFilterChanged);
    }
    // Add global keyboard listener
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Dispose filter controllers
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();
    _verticalScrollController.removeListener(_onScrollChanged);
    _verticalScrollController.dispose();
    for (final controller in _filterControllers) {
      controller.dispose();
    }
    // Remove global keyboard listener
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(ResizableDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the initial scroll positions changed, update the scroll controllers
    if (oldWidget.initialScrollPositions.horizontal !=
        widget.initialScrollPositions.horizontal) {
      debugPrint(
          'Restoring horizontal scroll position to: ${widget.initialScrollPositions.horizontal}');
      _scrollController.jumpTo(widget.initialScrollPositions.horizontal);
    }
    if (oldWidget.initialScrollPositions.vertical !=
        widget.initialScrollPositions.vertical) {
      debugPrint(
          'Restoring vertical scroll position to: ${widget.initialScrollPositions.vertical}');
      _verticalScrollController.jumpTo(widget.initialScrollPositions.vertical);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes if needed
  }

  @override
  void didChangeMetrics() {
    // This method is called when the system metrics change
    // We can use it to detect keyboard events indirectly
  }

  void _onFilterChanged() {
    setState(() {
      // Trigger rebuild when filters change
    });
  }

  void _onScrollChanged() {
    final horizontal = _scrollController.offset;
    final vertical = _verticalScrollController.offset;
    debugPrint(
        'Scroll position changed: horizontal=$horizontal, vertical=$vertical');
    widget.onScrollPositionChanged
        ?.call((horizontal: horizontal, vertical: vertical));
  }

  /// Get filtered studies based on current filter values
  /*List<Study> get _filteredStudies {
    return widget.studies.where((study) {
      // Check ID filter
      if (_filterControllers[0].text.isNotEmpty) {
        if (!study.id
            .toLowerCase()
            .contains(_filterControllers[0].text.toLowerCase())) {
          return false;
        }
      }

      // Check Name filter
      if (_filterControllers[1].text.isNotEmpty) {
        if (!study.name
            .toLowerCase()
            .contains(_filterControllers[1].text.toLowerCase())) {
          return false;
        }
      }

      // Check Sex filter
      if (_filterControllers[2].text.isNotEmpty) {
        if (!study.sex
            .toLowerCase()
            .contains(_filterControllers[2].text.toLowerCase())) {
          return false;
        }
      }

      // Check Birth Date filter
      if (_filterControllers[3].text.isNotEmpty) {
        final dateStr = _formatDate(study.birthDate);
        if (!dateStr.contains(_filterControllers[3].text)) {
          return false;
        }
      }

      return true;
    }).toList();
  }*/

  // Helper method to get column width by index in display order
  double _getColumnWidth(int displayIndex) {
    if (displayIndex >= 0 && displayIndex < _columnOrder.length) {
      final columnId = _columnOrder[displayIndex];
      return _columnConfig.getWidthById(columnId) ?? 120.0;
    }
    return 120.0;
  }

  // Helper method to get column configuration by index in display order
  ColumnConfiguration? _getColumnConfig(int displayIndex) {
    if (displayIndex >= 0 && displayIndex < _columnOrder.length) {
      final columnId = _columnOrder[displayIndex];
      return _columnConfig.getById(columnId);
    }
    return null;
  }

  // Helper method to update column width
  void _updateColumnWidth(String columnId, double newWidth) {
    final column = _columnConfig.getById(columnId);
    if (column != null) {
      final updated = column.copyWith(
          width: newWidth.clamp(_minColumnWidth, _maxColumnWidth));
      _columnConfig = _columnConfig.updateColumn(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalColumnWidth = _sortedColumns.fold<double>(
          0.0,
          (sum, col) => sum + col.width,
        );
        final resizeHandlesWidth = _columnCount * 4.0;
        const toggleButtonWidth = 80.0;
        final totalWidth =
            totalColumnWidth + resizeHandlesWidth + toggleButtonWidth;

        // Use parent width if total width is smaller, otherwise use total width
        // This ensures the table fills the parent when it's smaller
        final tableWidth = totalWidth < constraints.maxWidth
            ? constraints.maxWidth
            : totalWidth;
        final shouldFillSpace = totalWidth < constraints.maxWidth;

        return Stack(
          key: _stackKey,
          children: [
            // Horizontal scroll view containing the entire table
            Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                controller: _scrollController,
                child: SizedBox(
                  width: tableWidth,
                  height: constraints.maxHeight,
                  child: Column(
                    children: [
                      // Header row
                      _buildHeaderRow(shouldFillSpace: shouldFillSpace),
                      // Filter bar
                      _buildFilterBar(shouldFillSpace: shouldFillSpace),
                      // Data rows with vertical scrolling
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _verticalScrollController,
                          child: Column(
                            children: widget.studies
                                .map((study) => _buildDataRow(study,
                                    shouldFillSpace: shouldFillSpace))
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Drag image overlay
            if (_isDraggingColumn &&
                _draggedColumnIndex != null &&
                _dragOffset != null)
              Positioned(
                left: _dragOffset!.dx -
                    (_getColumnWidth(_draggedColumnIndex!) /
                        2), // Center horizontally
                top: _dragOffset!.dy - 15, // Small offset above cursor
                child: Material(
                  elevation: 8.0,
                  borderRadius: BorderRadius.circular(4),
                  child: Builder(
                    builder: (context) {
                      final columnConfig =
                          _getColumnConfig(_draggedColumnIndex!);
                      return Container(
                        width: _getColumnWidth(_draggedColumnIndex!),
                        padding: const EdgeInsets.symmetric(
                          horizontal: OnisViewerConstants.paddingMedium,
                          vertical: OnisViewerConstants.paddingSmall,
                        ),
                        decoration: BoxDecoration(
                          color: OnisViewerConstants.primaryColor
                              .withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          columnConfig?.title ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Build the header row with resizable columns
  Widget _buildHeaderRow({bool shouldFillSpace = false}) {
    return Container(
      decoration: BoxDecoration(
        color: OnisViewerConstants.tabBarColor,
        border: Border(
          bottom: BorderSide(
            color: OnisViewerConstants.tabButtonColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          ..._columnOrder.asMap().entries.map((entry) {
            final displayIndex = entry.key;
            final columnId = entry.value;
            final columnConfig = _columnConfig.getById(columnId);
            if (columnConfig == null) return const SizedBox.shrink();

            return Row(
              children: [
                // Draggable header cell
                GestureDetector(
                  onPanStart: (details) {
                    final RenderBox? stackBox = _stackKey.currentContext
                        ?.findRenderObject() as RenderBox?;
                    if (stackBox != null) {
                      final localPosition =
                          stackBox.globalToLocal(details.globalPosition);
                      setState(() {
                        _isDraggingColumn = true;
                        _draggedColumnIndex = displayIndex;
                        _dragOffset = localPosition;
                      });
                    }
                  },
                  onPanUpdate: (details) {
                    final RenderBox? stackBox = _stackKey.currentContext
                        ?.findRenderObject() as RenderBox?;
                    if (stackBox != null) {
                      final localPosition =
                          stackBox.globalToLocal(details.globalPosition);
                      setState(() {
                        _dragOffset = localPosition;
                      });
                    }

                    // Calculate which column we're hovering over
                    final RenderBox renderBox =
                        context.findRenderObject() as RenderBox;
                    final localPosition =
                        renderBox.globalToLocal(details.globalPosition);

                    // Calculate the position of each column to determine drop target
                    double currentX = 0;
                    bool foundTarget = false;

                    for (int i = 0; i < _columnOrder.length; i++) {
                      final colWidth = _getColumnWidth(i);

                      // Check if mouse is within this column's bounds
                      if (localPosition.dx >= currentX &&
                          localPosition.dx <= currentX + colWidth) {
                        // If dragging over a different column, set it as drop target
                        if (i != _draggedColumnIndex) {
                          setState(() {
                            _dropTargetIndex = i;
                          });
                        } else {
                          // If dragging over the same column, clear the drop target
                          setState(() {
                            _dropTargetIndex = null;
                          });
                        }
                        foundTarget = true;
                        break;
                      }
                      currentX += colWidth;
                    }

                    // If not found in any column, check if we're at the end
                    if (!foundTarget && localPosition.dx > currentX) {
                      setState(() {
                        _dropTargetIndex =
                            _columnOrder.length; // Drop at the end
                      });
                    }
                  },
                  onPanEnd: (details) {
                    if (_draggedColumnIndex != null &&
                        _dropTargetIndex != null) {
                      _reorderColumn(_draggedColumnIndex!, _dropTargetIndex!);
                    }
                    setState(() {
                      _isDraggingColumn = false;
                      _draggedColumnIndex = null;
                      _dropTargetIndex = null;
                      _dragOffset = null;
                    });
                  },
                  child: ClipRect(
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: _draggedColumnIndex == displayIndex
                                ? OnisViewerConstants.surfaceColor
                                    .withValues(alpha: 0.5)
                                : _dropTargetIndex == displayIndex
                                    ? OnisViewerConstants.primaryColor
                                        .withValues(alpha: 0.2)
                                    : null,
                          ),
                          child: _buildHeaderCell(
                            columnConfig.title,
                            displayIndex,
                            isNumeric: columnConfig.isNumeric,
                          ),
                        ),
                        if (_dropTargetIndex == displayIndex)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: OnisViewerConstants.primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Resize handle
                _buildResizeHandle(displayIndex),
              ],
            );
          }),
          // Add spacer to fill remaining space when table is smaller than parent
          if (shouldFillSpace) const Spacer(),
        ],
      ),
    );
  }

  /// Reorder columns based on drag and drop
  void _reorderColumn(int draggedIndex, int targetIndex) {
    if (draggedIndex < 0 || draggedIndex >= _columnOrder.length) return;
    if (targetIndex < 0 || targetIndex > _columnOrder.length) return;

    final draggedColumnId = _columnOrder[draggedIndex];
    final oldIndex = draggedIndex;

    // If dropping on the same column, cancel the operation
    if (oldIndex == targetIndex) {
      return;
    }

    setState(() {
      // Remove the dragged column first
      _columnOrder.removeAt(oldIndex);

      // Insert at the target position
      // If dropping at the end (after last column), append to the end
      if (targetIndex >= _columnOrder.length) {
        _columnOrder.add(draggedColumnId);
      } else {
        _columnOrder.insert(targetIndex, draggedColumnId);
      }
    });
  }

  /// Build the filter bar
  Widget _buildFilterBar({bool shouldFillSpace = false}) {
    return Container(
      decoration: BoxDecoration(
        color: OnisViewerConstants.surfaceColor,
        border: Border(
          bottom: BorderSide(
            color: OnisViewerConstants.tabButtonColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          ..._columnOrder.asMap().entries.map((entry) {
            final displayIndex = entry.key;
            final columnId = entry.value;
            final columnConfig = _columnConfig.getById(columnId);
            if (columnConfig == null) return const SizedBox.shrink();

            String hintText;

            // Get the correct hint text based on column id
            switch (columnId) {
              case 'source':
                hintText = 'Filter Source...';
                break;
              case 'patientId':
                hintText = 'Filter Patient ID...';
                break;
              case 'patientName':
                hintText = 'Filter Patient Name...';
                break;
              case 'birthDate':
                hintText = 'Filter Birth Date...';
                break;
              case 'sex':
                hintText = 'Filter Sex...';
                break;
              case 'age':
                hintText = 'Filter Age...';
                break;
              case 'modalities':
                hintText = 'Filter Modalities...';
                break;
              case 'studyDate':
                hintText = 'Filter Study Date...';
                break;
              case 'studyTime':
                hintText = 'Filter Study Time...';
                break;
              case 'bodyParts':
                hintText = 'Filter Body Parts...';
                break;
              case 'accnum':
                hintText = 'Filter Accession Number...';
                break;
              case 'studyId':
                hintText = 'Filter Study ID...';
                break;
              case 'description':
                hintText = 'Filter Description...';
                break;
              case 'instanceNumber':
                hintText = 'Filter Instance Number...';
                break;
              case 'comment':
                hintText = 'Filter Comment...';
                break;
              case 'stations':
                hintText = 'Filter Stations...';
                break;
              case 'seriesCount':
                hintText = 'Filter Series Count...';
                break;
              case 'imagesCount':
                hintText = 'Filter Images Count...';
                break;
              case 'reportsCount':
                hintText = 'Filter Reports Count...';
                break;
              case 'status':
                hintText = 'Filter Status...';
                break;
              default:
                hintText = 'Filter...';
            }

            return Row(
              children: [
                // Filter cell
                _buildFilterCell(displayIndex, hintText),
                // Resize handle
                _buildResizeHandle(displayIndex),
              ],
            );
          }),
          // Add spacer to fill remaining space when table is smaller than parent
          if (shouldFillSpace) const Spacer(),
        ],
      ),
    );
  }

  /// Build a filter cell
  Widget _buildFilterCell(int displayIndex, String hintText) {
    return Container(
      width: _getColumnWidth(displayIndex),
      padding: const EdgeInsets.symmetric(
        horizontal: OnisViewerConstants.paddingSmall,
        vertical: OnisViewerConstants.paddingSmall,
      ),
      child: TextField(
        controller: _filterControllers[displayIndex],
        style: const TextStyle(
          color: OnisViewerConstants.textColor,
          fontSize: 12,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: OnisViewerConstants.textSecondaryColor,
            fontSize: 12,
          ),
          filled: true,
          fillColor: OnisViewerConstants.tabBarColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: OnisViewerConstants.tabButtonColor,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: OnisViewerConstants.tabButtonColor,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: OnisViewerConstants.primaryColor,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: OnisViewerConstants.paddingSmall,
            vertical: OnisViewerConstants.paddingSmall,
          ),
          isDense: true,
        ),
      ),
    );
  }

  /// Build a header cell
  Widget _buildHeaderCell(String label, int displayIndex,
      {bool isNumeric = false}) {
    return GestureDetector(
      onTap: () {
        widget.onSort?.call(
            widget.sortColumnIndex == displayIndex && widget.sortAscending
                ? null
                : displayIndex);
      },
      child: Container(
        width: _getColumnWidth(displayIndex),
        padding: const EdgeInsets.symmetric(
          horizontal: OnisViewerConstants.paddingMedium,
          vertical: OnisViewerConstants.paddingSmall,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: OnisViewerConstants.textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textAlign: isNumeric ? TextAlign.right : TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.sortColumnIndex == displayIndex)
              Icon(
                widget.sortAscending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                color: OnisViewerConstants.primaryColor,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  /// Build a resize handle
  Widget _buildResizeHandle(int displayIndex) {
    if (displayIndex >= _columnOrder.length) return const SizedBox.shrink();
    final columnId = _columnOrder[displayIndex];

    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          if (displayIndex < _isDragging.length) {
            _isDragging[displayIndex] = true;
          }
        });
      },
      onPanUpdate: (details) {
        setState(() {
          final currentWidth = _getColumnWidth(displayIndex);
          final newWidth = (currentWidth + details.delta.dx)
              .clamp(_minColumnWidth, _maxColumnWidth);
          _updateColumnWidth(columnId, newWidth);
        });
      },
      onPanEnd: (details) {
        setState(() {
          if (displayIndex < _isDragging.length) {
            _isDragging[displayIndex] = false;
          }
        });
      },
      // Don't handle tap events - let them pass through to the cell
      onTap: null,
      onTapDown: null,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: Container(
          width: 4, // Reduced from 8 to 4 pixels
          color:
              (displayIndex < _isDragging.length && _isDragging[displayIndex])
                  ? OnisViewerConstants.primaryColor.withValues(alpha: 0.3)
                  : Colors.transparent,
          child: Center(
            child: Container(
              width: 1, // Reduced from 2 to 1 pixel
              height: 20,
              decoration: BoxDecoration(
                color: (displayIndex < _isDragging.length &&
                        _isDragging[displayIndex])
                    ? OnisViewerConstants.primaryColor
                    : OnisViewerConstants.tabButtonColor,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build a data row
  Widget _buildDataRow(FindPatientStudyItem study,
      {bool shouldFillSpace = false}) {
    final isSelected = widget.selectedStudies.contains(study);

    return GestureDetector(
      onTapDown: (details) {
        // Check for modifier keys in the mouse event
        _handleRowSelection(study);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? OnisViewerConstants.primaryColor.withValues(alpha: 0.1)
              : OnisViewerConstants.surfaceColor,
          border: Border(
            bottom: BorderSide(
              color: OnisViewerConstants.tabButtonColor,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            ..._columnOrder.asMap().entries.map((entry) {
              final displayIndex = entry.key;
              final columnId = entry.value;
              final columnConfig = _columnConfig.getById(columnId);
              if (columnConfig == null) return const SizedBox.shrink();

              String cellData;

              // Get the correct data based on column id
              switch (columnId) {
                case 'source':
                  cellData = study.patient.sourceUid.isNotEmpty
                      ? study.patient.sourceUid
                      : 'N/A';
                  break;
                case 'patientId':
                  cellData = study.patient.pid.isNotEmpty
                      ? study.patient.pid
                      : study.patient.id;
                  break;
                case 'patientName':
                  // Concatenate name, ideogram, and phonetic
                  final parts = <String>[];
                  if (study.patient.name.isNotEmpty)
                    parts.add(study.patient.name);
                  if (study.patient.ideogram.isNotEmpty)
                    parts.add(study.patient.ideogram);
                  if (study.patient.phonetic.isNotEmpty)
                    parts.add('(${study.patient.phonetic})');
                  cellData = parts.join(' ');
                  break;
                case 'birthDate':
                  cellData = study.patient.birthDate != null
                      ? _formatDate(study.patient.birthDate!)
                      : 'N/A';
                  break;
                case 'sex':
                  cellData =
                      study.patient.sex.isNotEmpty ? study.patient.sex : 'N/A';
                  break;
                case 'age':
                  cellData =
                      study.study.age.isNotEmpty ? study.study.age : 'N/A';
                  break;
                case 'modalities':
                  cellData = study.study.modalities.isNotEmpty
                      ? study.study.modalities
                      : 'N/A';
                  break;
                case 'studyDate':
                  cellData = study.study.studyDate != null &&
                          study.study.studyDate!.isNotEmpty
                      ? _formatStudyDate(study.study.studyDate!)
                      : 'N/A';
                  break;
                case 'studyTime':
                  cellData = study.study.studyTime != null &&
                          study.study.studyTime!.isNotEmpty
                      ? study.study.studyTime!
                      : 'N/A';
                  break;
                case 'bodyParts':
                  cellData = study.study.bodyParts.isNotEmpty
                      ? study.study.bodyParts
                      : 'N/A';
                  break;
                case 'accnum':
                  cellData = study.study.accnum.isNotEmpty
                      ? study.study.accnum
                      : 'N/A';
                  break;
                case 'studyId':
                  cellData = study.study.studyId.isNotEmpty
                      ? study.study.studyId
                      : 'N/A';
                  break;
                case 'description':
                  cellData =
                      study.study.desc.isNotEmpty ? study.study.desc : 'N/A';
                  break;
                case 'instanceNumber':
                  cellData = study.study.imcnt.toString();
                  break;
                case 'comment':
                  cellData = study.study.comment.isNotEmpty
                      ? study.study.comment
                      : 'N/A';
                  break;
                case 'stations':
                  cellData = study.study.stations.isNotEmpty
                      ? study.study.stations
                      : 'N/A';
                  break;
                case 'seriesCount':
                  cellData = study.study.srcnt.toString();
                  break;
                case 'imagesCount':
                  cellData = study.study.imcnt.toString();
                  break;
                case 'reportsCount':
                  cellData = study.study.rptcnt.toString();
                  break;
                case 'status':
                  cellData = study.study.status.toString();
                  break;
                default:
                  cellData = 'N/A';
              }

              return Row(
                children: [
                  // Data cell
                  _buildDataCell(cellData, displayIndex, isSelected,
                      study.patient, study.study),
                  // Resize handle
                  _buildResizeHandle(displayIndex),
                ],
              );
            }),
            // Add spacer to fill remaining space when table is smaller than parent
            if (shouldFillSpace) const Spacer(),
          ],
        ),
      ),
    );
  }

  /// Build a data cell
  Widget _buildDataCell(String text, int displayIndex, bool isSelected,
      database.Patient patient, database.Study study) {
    return Container(
      width: _getColumnWidth(displayIndex),
      padding: const EdgeInsets.symmetric(
        horizontal: OnisViewerConstants.paddingMedium,
        vertical: OnisViewerConstants.paddingSmall,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected
              ? OnisViewerConstants.primaryColor
              : OnisViewerConstants.textColor,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Handle row selection with keyboard modifiers
  void _handleRowSelection(FindPatientStudyItem study) {
    final isCurrentlySelected = widget.selectedStudies.contains(study);

    if (isShiftPressed && _lastSelectedStudy != null) {
      // Range selection mode (Shift + click)
      final lastIndex =
          widget.studies.indexWhere((s) => s == _lastSelectedStudy);
      final currentIndex = widget.studies.indexWhere((s) => s == study);

      if (lastIndex != -1 && currentIndex != -1) {
        final startIndex = lastIndex < currentIndex ? lastIndex : currentIndex;
        final endIndex = lastIndex < currentIndex ? currentIndex : lastIndex;
        // Clear current selection and add range
        widget.selectedStudies.clear();
        for (int i = startIndex; i <= endIndex; i++) {
          widget.selectedStudies.add(widget.studies[i]);
        }
        widget.onStudySelectionChanged?.call();
      }
    } else if (isCtrlOrCmdPressed) {
      // Multi-selection mode (Ctrl/Cmd + click)
      if (isCurrentlySelected) {
        // Remove from selection
        widget.selectedStudies.remove(study);
      } else {
        // Add to selection
        widget.selectedStudies.add(study);
      }
      widget.onStudySelectionChanged?.call();
    } else {
      // Single selection mode
      if (isCurrentlySelected && widget.selectedStudies.length == 1) {
        // If only this item is selected, deselect it
        widget.selectedStudies.clear();
      } else {
        // Select only this item
        widget.selectedStudies.clear();
        widget.selectedStudies.add(study);
      }
      widget.onStudySelectionChanged?.call();
    }

    // Update last selected study for range selection
    _lastSelectedStudy = study;

    // Build list of selected Study objects for callbacks
    /*final selectedStudies = widget.studies
        .where((s) {
          final id = s.study.id.isNotEmpty ? s.study.id : s.study.uid;
          return _selectedStudyIds.contains(id);
        })
        .map((s) => _convertToStudy(s.patient, s.study))
        .toList();

    // Call the appropriate callback
    widget.onStudiesSelected?.call(selectedStudies);
    if (selectedStudies.length == 1) {
      widget.onStudySelected?.call(selectedStudies.first);
    }

    // Update UI
    setState(() {});*/
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Format study date from YYYYMMDD format
  String _formatStudyDate(String dateStr) {
    if (dateStr.length >= 8) {
      try {
        final year = dateStr.substring(0, 4);
        final month = dateStr.substring(4, 6);
        final day = dateStr.substring(6, 8);
        return '$day/$month/$year';
      } catch (e) {
        return dateStr;
      }
    }
    return dateStr;
  }

  bool get isShiftPressed =>
      HardwareKeyboard.instance.logicalKeysPressed
          .contains(LogicalKeyboardKey.shiftLeft) ||
      HardwareKeyboard.instance.logicalKeysPressed
          .contains(LogicalKeyboardKey.shiftRight);

  bool get isCtrlOrCmdPressed {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;
    return isMac
        ? keys.contains(LogicalKeyboardKey.metaLeft) ||
            keys.contains(LogicalKeyboardKey.metaRight)
        : keys.contains(LogicalKeyboardKey.controlLeft) ||
            keys.contains(LogicalKeyboardKey.controlRight);
  }
}
