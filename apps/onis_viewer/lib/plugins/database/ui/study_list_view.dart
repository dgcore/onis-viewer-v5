import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../models/study.dart';
import 'resizable_data_table.dart';

/// Study list view using resizable data table
class StudyListView extends StatefulWidget {
  final List<Study> studies;
  final List<Study> selectedStudies; // Changed from Study? to List<Study>
  final ValueChanged<Study>? onStudySelected;
  final ValueChanged<List<Study>>?
      onStudiesSelected; // New callback for multi-selection
  final bool isCtrlPressed; // Keyboard modifier state
  final bool isShiftPressed; // Keyboard modifier state
  final VoidCallback? onAddStudy;
  final VoidCallback? onRefreshStudies;

  const StudyListView({
    super.key,
    required this.studies,
    required this.selectedStudies, // Changed from optional to required
    this.onStudySelected,
    this.onStudiesSelected, // New callback
    this.isCtrlPressed = false,
    this.isShiftPressed = false,
    this.onAddStudy,
    this.onRefreshStudies,
  });

  @override
  State<StudyListView> createState() => _StudyListViewState();
}

class _StudyListViewState extends State<StudyListView> {
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        _buildHeader(),

        // Study table
        Expanded(
          child: _buildStudyTable(),
        ),
      ],
    );
  }

  /// Build the header section
  Widget _buildHeader() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(
        horizontal: OnisViewerConstants.paddingMedium,
      ),
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
          const Icon(
            Icons.medical_services,
            color: OnisViewerConstants.textColor,
            size: 20,
          ),
          const SizedBox(width: OnisViewerConstants.marginSmall),
          Expanded(
            child: Text(
              'Studies (${widget.studies.length})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: OnisViewerConstants.textColor,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onRefreshStudies,
            icon: const Icon(
              Icons.refresh,
              color: OnisViewerConstants.textSecondaryColor,
              size: 18,
            ),
            tooltip: 'Refresh studies',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
          IconButton(
            onPressed: widget.onAddStudy,
            icon: const Icon(
              Icons.add,
              color: OnisViewerConstants.textSecondaryColor,
              size: 18,
            ),
            tooltip: 'Add study',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }

  /// Build the study table
  Widget _buildStudyTable() {
    final sortedStudies = List<Study>.from(widget.studies);

    if (_sortColumnIndex != null) {
      sortedStudies.sort((a, b) {
        int comparison = 0;
        switch (_sortColumnIndex) {
          case 0: // ID
            comparison = a.id.compareTo(b.id);
            break;
          case 1: // Name
            comparison = a.name.compareTo(b.name);
            break;
          case 2: // Sex
            comparison = a.sex.compareTo(b.sex);
            break;
          case 3: // Birth Date
            comparison = a.birthDate.compareTo(b.birthDate);
            break;
        }
        return _sortAscending ? comparison : -comparison;
      });
    }

    return ResizableDataTable(
      studies: sortedStudies,
      selectedStudies: widget.selectedStudies,
      onStudySelected: widget.onStudySelected,
      onStudiesSelected: widget.onStudiesSelected,
      isCtrlPressed: widget.isCtrlPressed,
      isShiftPressed: widget.isShiftPressed,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      onSort: (columnIndex) {
        setState(() {
          if (_sortColumnIndex == columnIndex) {
            _sortAscending = !_sortAscending;
          } else {
            _sortColumnIndex = columnIndex;
            _sortAscending = true;
          }
        });
      },
    );
  }
}
