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

  const ResizableDataTable({
    super.key,
    required this.studies,
    required this.selectedStudies, // Changed from optional to required
    this.onStudySelected,
    this.onStudiesSelected, // New callback
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
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

  // Filter controllers
  final List<TextEditingController> _filterControllers = [
    TextEditingController(), // ID filter
    TextEditingController(), // Name filter
    TextEditingController(), // Sex filter
    TextEditingController(), // Birth Date filter
  ];

  // Selection state
  Study? _lastSelectedStudy; // Track last selected study for range selection

  @override
  void initState() {
    super.initState();
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
    for (final controller in _filterControllers) {
      controller.dispose();
    }
    // Remove global keyboard listener
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
        children: [
          // Patient ID column header
          _buildHeaderCell('Patient ID', 0, isNumeric: false),
          _buildResizeHandle(0),

          // Name column header
          _buildHeaderCell('Name', 1, isNumeric: false),
          _buildResizeHandle(1),

          // Sex column header
          _buildHeaderCell('Sex', 2, isNumeric: false),
          _buildResizeHandle(2),

          // Birth Date column header
          _buildHeaderCell('Birth Date', 3, isNumeric: false),
          _buildResizeHandle(3),
        ],
      ),
    );
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
        children: [
          // Patient ID filter
          _buildFilterCell(0, 'Filter Patient ID...'),
          _buildResizeHandle(0),

          // Name filter
          _buildFilterCell(1, 'Filter Name...'),
          _buildResizeHandle(1),

          // Sex filter
          _buildFilterCell(2, 'Filter Sex...'),
          _buildResizeHandle(2),

          // Birth Date filter
          _buildFilterCell(3, 'Filter Date...'),
          _buildResizeHandle(3),
        ],
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
          children: [
            // Patient ID cell
            _buildDataCell(study.patientId ?? 'N/A', 0, isSelected, study),
            _buildResizeHandle(0),

            // Name cell
            _buildDataCell(study.name, 1, isSelected, study),
            _buildResizeHandle(1),

            // Sex cell
            _buildDataCell(study.sex, 2, isSelected, study),
            _buildResizeHandle(2),

            // Birth Date cell
            _buildDataCell(_formatDate(study.birthDate), 3, isSelected, study),
            _buildResizeHandle(3),
          ],
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
