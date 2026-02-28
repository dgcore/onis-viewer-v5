import 'package:flutter/material.dart';
import 'package:onis_viewer/api/ov_api.dart';
import 'package:onis_viewer/core/models/database/filter.dart';
import 'package:onis_viewer/core/responses/find_study_response.dart';
import 'package:onis_viewer/plugins/database/public/database_api.dart';

import '../../../core/constants.dart';
import '../../../core/models/database/patient.dart' as database;

/// Dialog for retrieving series with progress indication
class RetrieveSeriesDialog extends StatefulWidget {
  final List<database.Patient> patients;

  const RetrieveSeriesDialog({super.key, required this.patients});

  /// Show the retrieve series dialog
  static Future<List<FindPatientStudyItem>?> show(
    BuildContext context, {
    required List<database.Patient> patients,
  }) {
    return showDialog<List<FindPatientStudyItem>?>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext dialogContext) {
        return RetrieveSeriesDialog(
          patients: patients,
        );
      },
    );
  }

  @override
  State<RetrieveSeriesDialog> createState() => _RetrieveSeriesDialogState();
}

class _RetrieveSeriesDialogState extends State<RetrieveSeriesDialog> {
  double _progress = 0.0;
  bool _isCancelled = false;
  int _currentIndex = 0;
  final List<FindPatientStudyItem> _items = [];

  @override
  void initState() {
    super.initState();
    _retrieveNextItem();
  }

  void _handleCancel() {
    setState(() {
      _isCancelled = true;
    });
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: OnisViewerConstants.surfaceColor,
      title: const Text(
        'Retrieving Series',
        style: TextStyle(
          color: OnisViewerConstants.textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: OnisViewerConstants.tabButtonColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                OnisViewerConstants.primaryColor,
              ),
              minHeight: 8,
            ),
            const SizedBox(height: 16),
            // Progress text
            Text(
              '${(_progress * 100).toStringAsFixed(0)}%',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: OnisViewerConstants.textSecondaryColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            // Status text
            Text(
              _isCancelled
                  ? 'Cancelling...'
                  : _progress >= 1.0
                      ? 'Complete'
                      : 'Retrieving series data...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: OnisViewerConstants.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCancelled ? null : _handleCancel,
          child: Text(
            'Cancel',
            style: TextStyle(
              color: _isCancelled
                  ? OnisViewerConstants.textSecondaryColor
                      .withValues(alpha: 0.5)
                  : OnisViewerConstants.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _retrieveNextItem() async {
    DatabaseApi? dbApi =
        OVApi().plugins.getPublicApi<DatabaseApi>('onis_database_plugin');
    final sourceController = dbApi?.sourceController;
    if (_isCancelled ||
        _currentIndex == widget.patients.length ||
        sourceController == null) {
      if (_isCancelled) {
        Navigator.of(context).pop(null);
      } else {
        Navigator.of(context).pop(_items);
      }
    } else {
      final patient = widget.patients[_currentIndex];
      DBFilters filters = DBFilters();
      filters.pid.value = patient.pid;
      filters.pid.type = 0;
      filters.studyDateMode.value = DBFilters.any;
      final response = await sourceController.findStudies(patient.sourceUid,
          filters: filters, withSeries: true);
      if (response.status == 0) {
        for (final sourceResponse in response.sources) {
          _items.addAll(sourceResponse.studies);
        }
      }
      setState(() {
        _progress = _currentIndex / widget.patients.length;
      });
      _currentIndex++;
      _progress = _currentIndex / widget.patients.length;
      _retrieveNextItem();
    }
  }
}
