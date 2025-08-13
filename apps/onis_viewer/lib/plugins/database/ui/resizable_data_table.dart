import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants.dart';
import '../../../core/models/study.dart';

/// A resizable data table that allows column width adjustment
class ResizableDataTable extends StatefulWidget {
  final List<Study> studies;
  final List<Study> selectedStudies; // Changed from Study? to List<Study>
  final ValueChanged<Study>? onStudySelected;
  final ValueChanged<List<Study>>?
      onStudiesSelected; // New callback for multi-selection
  final int? sortColumnIndex;
  final bool sortAscending;
  final ValueChanged<int?>? onSort;
  final double initialScrollPosition;
  final ValueChanged<double>? onScrollPositionChanged;

  const ResizableDataTable({
    super.key,
    required this.studies,
    required this.selectedStudies, // Changed from optional to required
    this.onStudySelected,
    this.onStudiesSelected, // New callback
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
    this.initialScrollPosition = 0.0,
    this.onScrollPositionChanged,
  });

  @override
  State<ResizableDataTable> createState() => _ResizableDataTableState();
}

class _ResizableDataTableState extends State<ResizableDataTable>
    with WidgetsBindingObserver {
  final List<double> _columnWidths = [
    150.0,
    200.0,
    100.0,
    150.0
  ]; // ID, Name, Sex, Birth Date
  final List<bool> _isDragging = [false, false, false, false];
  final double _minColumnWidth = 80.0;
  final double _maxColumnWidth = 400.0;

  // Column reordering state
  final List<int> _columnOrder = [
    0,
    1,
    2,
    3
  ]; // Default order: Patient ID, Name, Sex, Birth Date
  int? _draggedColumnIndex;
  int? _dropTargetIndex;
  bool _isDraggingColumn = false;

  // Column definitions
  final List<Map<String, dynamic>> _columnDefinitions = [
    {'title': 'Patient ID', 'key': 'patientId', 'isNumeric': false},
    {'title': 'Name', 'key': 'name', 'isNumeric': false},
    {'title': 'Sex', 'key': 'sex', 'isNumeric': false},
    {'title': 'Birth Date', 'key': 'birthDate', 'isNumeric': false},
  ];

  // Filter controllers
  final List<TextEditingController> _filterControllers = [
    TextEditingController(), // ID filter
    TextEditingController(), // Name filter
    TextEditingController(), // Sex filter
    TextEditingController(), // Birth Date filter
  ];

  // Selection state
  Study? _lastSelectedStudy; // Track last selected study for range selection
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController =
        ScrollController(initialScrollOffset: widget.initialScrollPosition);
    _scrollController.addListener(_onScrollChanged);

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

    // If the initial scroll position changed, update the scroll controller
    if (oldWidget.initialScrollPosition != widget.initialScrollPosition) {
      debugPrint(
          'Restoring scroll position to: ${widget.initialScrollPosition}');
      _scrollController.jumpTo(widget.initialScrollPosition);
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
    debugPrint('Scroll position changed: ${_scrollController.offset}');
    widget.onScrollPositionChanged?.call(_scrollController.offset);
  }

  /// Get filtered studies based on current filter values
  List<Study> get _filteredStudies {
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
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalColumnWidth = _columnWidths.reduce((a, b) => a + b);
        final resizeHandlesWidth = _columnWidths.length * 4.0;
        const toggleButtonWidth = 80.0;
        final totalWidth =
            totalColumnWidth + resizeHandlesWidth + toggleButtonWidth;
        final availableWidth = constraints.maxWidth;
        final needsHorizontalScroll = totalWidth > availableWidth;

        return Column(
          children: [
            // Sticky header and filter bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: needsHorizontalScroll ? totalWidth : availableWidth,
                child: Column(
                  children: [
                    // Header row
                    _buildHeaderRow(),
                    // Filter bar
                    _buildFilterBar(),
                  ],
                ),
              ),
            ),
            // Scrollable data rows
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: SizedBox(
                    width: needsHorizontalScroll ? totalWidth : availableWidth,
                    child: Column(
                      children: _filteredStudies
                          .map((study) => _buildDataRow(study))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build the header row with resizable columns
  Widget _buildHeaderRow() {
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
        children: _columnOrder.asMap().entries.map((entry) {
          final displayIndex = entry.key;
          final columnIndex = entry.value;
          final columnDef = _columnDefinitions[columnIndex];

          return Row(
            children: [
              // Draggable header cell
              GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _isDraggingColumn = true;
                    _draggedColumnIndex = columnIndex;
                  });
                },
                onPanUpdate: (details) {
                  // Calculate which column we're hovering over
                  final RenderBox renderBox =
                      context.findRenderObject() as RenderBox;
                  final localPosition =
                      renderBox.globalToLocal(details.globalPosition);

                  // Calculate the position of each column to determine drop target
                  double currentX = 0;
                  bool foundTarget = false;

                  for (int i = 0; i < _columnOrder.length; i++) {
                    final colIndex = _columnOrder[i];
                    final colWidth = _columnWidths[colIndex];

                    // Check if mouse is within this column's bounds
                    if (localPosition.dx >= currentX &&
                        localPosition.dx <= currentX + colWidth) {
                      // If dragging over a different column, set it as drop target
                      if (colIndex != _draggedColumnIndex) {
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
                      _dropTargetIndex = _columnOrder.length; // Drop at the end
                    });
                  }
                },
                onPanEnd: (details) {
                  if (_draggedColumnIndex != null && _dropTargetIndex != null) {
                    _reorderColumn(_draggedColumnIndex!, _dropTargetIndex!);
                  }
                  setState(() {
                    _isDraggingColumn = false;
                    _draggedColumnIndex = null;
                    _dropTargetIndex = null;
                  });
                },
                child: ClipRect(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: _draggedColumnIndex == columnIndex
                              ? OnisViewerConstants.surfaceColor
                                  .withValues(alpha: 0.5)
                              : _dropTargetIndex == displayIndex
                                  ? OnisViewerConstants.primaryColor
                                      .withValues(alpha: 0.2)
                                  : null,
                        ),
                        child: _buildHeaderCell(columnDef['title'], columnIndex,
                            isNumeric: columnDef['isNumeric']),
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
              _buildResizeHandle(columnIndex),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Reorder columns based on drag and drop
  void _reorderColumn(int draggedColumn, int targetIndex) {
    final oldIndex = _columnOrder.indexOf(draggedColumn);

    // If dropping on the same column, cancel the operation
    if (oldIndex == targetIndex) {
      return;
    }

    if (oldIndex != -1 &&
        targetIndex >= 0 &&
        targetIndex <= _columnOrder.length &&
        oldIndex != targetIndex) {
      setState(() {
        // Remove the dragged column first
        _columnOrder.removeAt(oldIndex);

        // Insert at the target position
        // If dropping at the end (after last column), append to the end
        if (targetIndex >= _columnOrder.length) {
          _columnOrder.add(draggedColumn);
        } else {
          _columnOrder.insert(targetIndex, draggedColumn);
        }
      });
    }
  }

  /// Build the filter bar
  Widget _buildFilterBar() {
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
        children: _columnOrder.map((columnIndex) {
          final columnDef = _columnDefinitions[columnIndex];
          String hintText;

          // Get the correct hint text based on column definition
          switch (columnDef['key']) {
            case 'patientId':
              hintText = 'Filter Patient ID...';
              break;
            case 'name':
              hintText = 'Filter Name...';
              break;
            case 'sex':
              hintText = 'Filter Sex...';
              break;
            case 'birthDate':
              hintText = 'Filter Date...';
              break;
            default:
              hintText = 'Filter...';
          }

          return Row(
            children: [
              // Filter cell
              _buildFilterCell(columnIndex, hintText),
              // Resize handle
              _buildResizeHandle(columnIndex),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Build a filter cell
  Widget _buildFilterCell(int columnIndex, String hintText) {
    return Container(
      width: _columnWidths[columnIndex],
      padding: const EdgeInsets.symmetric(
        horizontal: OnisViewerConstants.paddingSmall,
        vertical: OnisViewerConstants.paddingSmall,
      ),
      child: TextField(
        controller: _filterControllers[columnIndex],
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
  Widget _buildHeaderCell(String label, int columnIndex,
      {bool isNumeric = false}) {
    return GestureDetector(
      onTap: () {
        widget.onSort?.call(
            widget.sortColumnIndex == columnIndex && widget.sortAscending
                ? null
                : columnIndex);
      },
      child: Container(
        width: _columnWidths[columnIndex],
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
              ),
            ),
            if (widget.sortColumnIndex == columnIndex)
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
  Widget _buildResizeHandle(int columnIndex) {
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _isDragging[columnIndex] = true;
        });
      },
      onPanUpdate: (details) {
        setState(() {
          _columnWidths[columnIndex] =
              (_columnWidths[columnIndex] + details.delta.dx)
                  .clamp(_minColumnWidth, _maxColumnWidth);
        });
      },
      onPanEnd: (details) {
        setState(() {
          _isDragging[columnIndex] = false;
        });
      },
      // Don't handle tap events - let them pass through to the cell
      onTap: null,
      onTapDown: null,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: Container(
          width: 4, // Reduced from 8 to 4 pixels
          color: _isDragging[columnIndex]
              ? OnisViewerConstants.primaryColor.withValues(alpha: 0.3)
              : Colors.transparent,
          child: Center(
            child: Container(
              width: 1, // Reduced from 2 to 1 pixel
              height: 20,
              decoration: BoxDecoration(
                color: _isDragging[columnIndex]
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
  Widget _buildDataRow(Study study) {
    final isSelected = widget.selectedStudies.any((s) => s.id == study.id);

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
          children: _columnOrder.map((columnIndex) {
            final columnDef = _columnDefinitions[columnIndex];
            String cellData;

            // Get the correct data based on column definition
            switch (columnDef['key']) {
              case 'patientId':
                cellData = study.patientId ?? 'N/A';
                break;
              case 'name':
                cellData = study.name;
                break;
              case 'sex':
                cellData = study.sex;
                break;
              case 'birthDate':
                cellData = _formatDate(study.birthDate);
                break;
              default:
                cellData = 'N/A';
            }

            return Row(
              children: [
                // Data cell
                _buildDataCell(cellData, columnIndex, isSelected, study),
                // Resize handle
                _buildResizeHandle(columnIndex),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Build a data cell
  Widget _buildDataCell(
      String text, int columnIndex, bool isSelected, Study study) {
    return Container(
      width: _columnWidths[columnIndex],
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
  void _handleRowSelection(Study study) {
    debugPrint('Row selection triggered for study: ${study.name}');
    print("Shift pressed: $isShiftPressed");
    print("Ctrl/Cmd pressed: $isCtrlOrCmdPressed");

    final currentSelection = List<Study>.from(widget.selectedStudies);
    final isCurrentlySelected = currentSelection.any((s) => s.id == study.id);

    debugPrint('Current selection count: ${currentSelection.length}');
    debugPrint('Is currently selected: $isCurrentlySelected');
    debugPrint(
        'Ctrl pressed: $isCtrlOrCmdPressed, Shift pressed: $isShiftPressed');

    if (isShiftPressed && _lastSelectedStudy != null) {
      // Range selection mode (Shift + click)
      final lastIndex =
          _filteredStudies.indexWhere((s) => s.id == _lastSelectedStudy!.id);
      final currentIndex = _filteredStudies.indexWhere((s) => s.id == study.id);

      if (lastIndex != -1 && currentIndex != -1) {
        final startIndex = lastIndex < currentIndex ? lastIndex : currentIndex;
        final endIndex = lastIndex < currentIndex ? currentIndex : lastIndex;

        // Clear current selection and add range
        currentSelection.clear();
        for (int i = startIndex; i <= endIndex; i++) {
          currentSelection.add(_filteredStudies[i]);
        }
        debugPrint(
            'Range selection from index $startIndex to $endIndex (${currentSelection.length} studies)');
      }
    } else if (isCtrlOrCmdPressed) {
      // Multi-selection mode (manual toggle or Ctrl/Cmd + click)
      if (isCurrentlySelected) {
        // Remove from selection
        currentSelection.removeWhere((s) => s.id == study.id);
        debugPrint('Removed from selection');
      } else {
        // Add to selection
        currentSelection.add(study);
        debugPrint('Added to selection');
      }
    } else {
      // Single selection mode
      if (isCurrentlySelected && currentSelection.length == 1) {
        // If only this item is selected, deselect it
        currentSelection.clear();
        debugPrint('Deselected single item');
      } else {
        // Select only this item
        currentSelection.clear();
        currentSelection.add(study);
        debugPrint('Selected single item');
      }
    }

    // Update last selected study for range selection
    _lastSelectedStudy = study;

    debugPrint('Final selection count: ${currentSelection.length}');

    // Call the appropriate callback
    debugPrint(
        'Calling onStudiesSelected with ${currentSelection.length} studies');
    widget.onStudiesSelected?.call(currentSelection);
    if (currentSelection.length == 1) {
      debugPrint('Calling onStudySelected with single study');
      widget.onStudySelected?.call(currentSelection.first);
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
