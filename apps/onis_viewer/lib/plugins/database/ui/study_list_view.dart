import 'package:flutter/material.dart';

import '../../../core/constants.dart';
import '../../../core/models/study.dart';
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This logic is no longer needed as scroll position is managed by DatabaseController
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        _buildHeader(),

        // Study table
        Expanded(
          child: Stack(
            children: [
              _buildStudyTable(),
              // Overlay to block interactions when disconnecting
              if (widget.isDisconnecting)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 8.0),
                            padding: EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              color: OnisViewerConstants.surfaceColor,
                              border: Border.all(
                                color: OnisViewerConstants.primaryColor,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: LinearProgressIndicator(
                              color: OnisViewerConstants.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
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
        color: widget.isDisconnecting
            ? OnisViewerConstants.tabBarColor.withOpacity(0.5)
            : OnisViewerConstants.tabBarColor,
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.isDisconnecting
                    ? OnisViewerConstants.textSecondaryColor
                    : OnisViewerConstants.textColor,
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
            // Debug: Log button state
            onPressed: () {
              debugPrint(
                  'Disconnect button state - isDisconnecting: ${widget.isDisconnecting}');
              if (widget.isDisconnecting) {
                debugPrint('Button is disabled due to isDisconnecting');
                return;
              }
              debugPrint('Disconnect IconButton pressed');
              if (widget.onDisconnect != null) {
                debugPrint('Calling onDisconnect callback');
                widget.onDisconnect!();
              } else {
                debugPrint('onDisconnect callback is null');
              }
            },
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
          case 0: // Patient ID
            comparison = (a.patientId ?? '').compareTo(b.patientId ?? '');
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
      key: ValueKey('default'), // Use source key to maintain widget identity
      studies: sortedStudies,
      selectedStudies: widget.selectedStudies,
      onStudySelected: widget.isDisconnecting ? null : widget.onStudySelected,
      onStudiesSelected:
          widget.isDisconnecting ? null : widget.onStudiesSelected,
      isCtrlPressed: widget.isCtrlPressed,
      isShiftPressed: widget.isShiftPressed,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      onSort: widget.isDisconnecting
          ? null
          : (columnIndex) {
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
