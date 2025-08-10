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
  final String? username; // Current logged-in username
  final VoidCallback? onDisconnect; // Disconnect callback
  final bool isDisconnecting; // Whether currently disconnecting

  const StudyListView({
    super.key,
    required this.studies,
    required this.selectedStudies, // Changed from optional to required
    this.onStudySelected,
    this.onStudiesSelected, // New callback
    this.isCtrlPressed = false,
    this.isShiftPressed = false,
    this.username,
    this.onDisconnect,
    this.isDisconnecting = false,
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
      padding: const EdgeInsets.symmetric(
        horizontal: OnisViewerConstants.paddingMedium,
        vertical: OnisViewerConstants.paddingSmall,
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
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: OnisViewerConstants.textColor,
                fontSize: 16,
              ),
            ),
          ),
          if (widget.username != null) ...[
            Text(
              'Logged in as: ${widget.username}',
              style: const TextStyle(
                color: OnisViewerConstants.textSecondaryColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
          ],
          IconButton(
            onPressed: widget.isDisconnecting ? null : widget.onDisconnect,
            icon: widget.isDisconnecting
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          OnisViewerConstants.textSecondaryColor),
                    ),
                  )
                : const Icon(
                    Icons.logout,
                    color: OnisViewerConstants.textSecondaryColor,
                    size: 18,
                  ),
            tooltip: widget.isDisconnecting ? 'Disconnecting...' : 'Disconnect',
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
