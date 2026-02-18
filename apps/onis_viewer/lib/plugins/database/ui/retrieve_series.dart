import 'package:flutter/material.dart';
import 'package:onis_viewer/api/ov_api.dart';
import 'package:onis_viewer/core/models/database/filter.dart';
import 'package:onis_viewer/plugins/database/public/database_api.dart';

import '../../../core/constants.dart';
import '../../../core/models/database/patient.dart' as database;
import '../../../core/models/database/study.dart' as database;

/// Dialog for retrieving series with progress indication
class RetrieveSeriesDialog extends StatefulWidget {
  final List<database.Patient> patients;
  final ({database.Patient patient, database.Study study})? primary;

  const RetrieveSeriesDialog({
    super.key,
    required this.patients,
    this.primary,
  });

  /// Show the retrieve series dialog
  static Future<bool?> show(
    BuildContext context, {
    required List<database.Patient> patients,
    ({database.Patient patient, database.Study study})? primary,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext dialogContext) {
        return RetrieveSeriesDialog(
          patients: patients,
          primary: primary,
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

  @override
  void initState() {
    super.initState();
    _retrieveNextItem();
  }

  void _handleCancel() {
    setState(() {
      _isCancelled = true;
    });
    Navigator.of(context).pop(false); // Return false to indicate cancellation
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
      Navigator.of(context).pop(false);
      /*if (this.canceled) this._cleanup();
      if (this.request.error.length == 0) this.complete.emit(this._output);
      this._cleanup();*/
    } else {
      final patient = widget.patients[_currentIndex];
      DBFilters filters = DBFilters();
      filters.pid.value = patient.id;
      filters.pid.type = 0;
      filters.studyDateMode.value = DBFilters.any;
      final response = await sourceController.findStudies(patient.sourceUid,
          filters: filters, withSeries: true);
      setState(() {
        _progress = _currentIndex / widget.patients.length;
      });
      _currentIndex++;
      _progress = _currentIndex / widget.patients.length;
      _retrieveNextItem();
    }
  }
}
