import 'package:flutter/material.dart';
import 'package:onis_viewer/api/core/ov_api_core.dart';
import 'package:onis_viewer/core/models/entities/patient.dart' as entities;
import 'package:onis_viewer/plugins/database/public/database_api.dart';

import '../../../core/constants.dart';

String _formatStudyDate(String? dateStr) {
  if (dateStr == null || dateStr.length < 8) return dateStr ?? '—';
  try {
    final year = dateStr.substring(0, 4);
    final month = dateStr.substring(4, 6);
    final day = dateStr.substring(6, 8);
    return '$day/$month/$year';
  } catch (e) {
    return dateStr;
  }
}

/// History bar widget for the viewer page
/// Fixed width, displayed on the left side, uses remaining height
class ViewerHistoryBar extends StatefulWidget {
  final double width;
  final List<String> historyItems;

  const ViewerHistoryBar({
    super.key,
    this.width = 250.0,
    this.historyItems = const [],
  });

  @override
  State<ViewerHistoryBar> createState() => _ViewerHistoryBarState();
}

class _ViewerHistoryBarState extends State<ViewerHistoryBar> {
  /// Currently selected patient for display (null = use fixed placeholder)
  entities.Patient? _selectedPatient;

  static const String _placeholderPatientId = '—';
  static const String _placeholderPatientName = '-';
  static const String _placeholderSex = '-';

  String get _displayPatientId =>
      _selectedPatient?.databaseInfo?.pid ??
      _selectedPatient?.databaseInfo?.id ??
      _placeholderPatientId;
  String get _displayPatientName =>
      _selectedPatient?.databaseInfo?.name ?? _placeholderPatientName;
  String get _displaySex =>
      _selectedPatient?.databaseInfo?.sex.isNotEmpty == true
          ? _selectedPatient!.databaseInfo!.sex
          : _placeholderSex;

  @override
  Widget build(BuildContext context) {
    final patientController = OVApi()
        .plugins
        .getPublicApi<DatabaseApi>('onis_database_plugin')
        ?.patientController;

    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: OnisViewerConstants.surfaceColor,
        border: Border(
          right: BorderSide(
            color: OnisViewerConstants.tabButtonColor,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient header: black container with ID, name, sex + selector button
          Container(
            padding: const EdgeInsets.all(OnisViewerConstants.paddingMedium),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(
                bottom: BorderSide(
                  color: OnisViewerConstants.tabButtonColor,
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _displayPatientId,
                        style: const TextStyle(
                          color: OnisViewerConstants.textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: OnisViewerConstants.marginSmall),
                      Text(
                        _displayPatientName,
                        style: const TextStyle(
                          color: OnisViewerConstants.textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: OnisViewerConstants.marginSmall),
                      Text(
                        _displaySex,
                        style: const TextStyle(
                          color: OnisViewerConstants.textSecondaryColor,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Small button to select a different patient
                if (patientController != null)
                  Builder(
                    builder: (buttonContext) {
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showPatientMenu(
                              buttonContext, patientController),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.person_search,
                              size: 20,
                              color: OnisViewerConstants.textSecondaryColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          // Studies and series list
          Expanded(
            child: patientController != null
                ? AnimatedBuilder(
                    animation: patientController as Listenable,
                    builder: (context, child) {
                      return _buildStudiesContent(context);
                    },
                  )
                : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  void _showPatientMenu(BuildContext context, dynamic patientController) {
    final patients = patientController.patients as List<entities.Patient>;
    if (patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No patients opened'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    showMenu<entities.Patient>(
      context: context,
      position: _getMenuPosition(context),
      items: [
        for (final patient in patients)
          PopupMenuItem<entities.Patient>(
            value: patient,
            child: Row(
              children: [
                SizedBox(
                  width: 20 + OnisViewerConstants.marginSmall,
                  child: patient == _selectedPatient
                      ? const Icon(
                          Icons.check,
                          color: OnisViewerConstants.primaryColor,
                          size: 20,
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: Text(
                    patient.databaseInfo?.name ?? 'Unknown',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: OnisViewerConstants.textColor,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ).then((entities.Patient? selected) {
      if (selected != null && mounted) {
        setState(() => _selectedPatient = selected);
      }
    });
  }

  RelativeRect _getMenuPosition(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return const RelativeRect.fromLTRB(0, 0, 100, 100);
    }
    final buttonTopLeft = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;
    // Anchor rect = the button; showMenu places the menu below this rect
    return RelativeRect.fromLTRB(
      buttonTopLeft.dx,
      buttonTopLeft.dy,
      buttonTopLeft.dx + buttonSize.width,
      buttonTopLeft.dy + buttonSize.height,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(OnisViewerConstants.paddingLarge),
        child: Text(
          'Select a patient',
          style: TextStyle(
            color: OnisViewerConstants.textSecondaryColor,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildStudiesContent(BuildContext context) {
    final patient = _selectedPatient;
    if (patient == null) {
      return _buildEmptyState();
    }
    final studies = patient.studies;
    if (studies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(OnisViewerConstants.paddingLarge),
          child: Text(
            'No studies',
            style: TextStyle(
              color: OnisViewerConstants.textSecondaryColor,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        vertical: OnisViewerConstants.paddingSmall,
        horizontal: OnisViewerConstants.paddingMedium,
      ),
      itemCount: studies.length,
      itemBuilder: (context, index) {
        return _StudySection(study: studies[index]);
      },
    );
  }
}

/// One study block: header (date, body parts, modalities) + series grid
class _StudySection extends StatelessWidget {
  final entities.Study study;

  const _StudySection({required this.study});

  @override
  Widget build(BuildContext context) {
    final db = study.databaseInfo;
    final dateStr = db?.studyDate != null && db!.studyDate!.isNotEmpty
        ? _formatStudyDate(db.studyDate)
        : '—';
    final bodyParts =
        (db?.bodyParts ?? '').trim().isEmpty ? '—' : (db?.bodyParts ?? '—');
    final modalities =
        (db?.modalities ?? '').trim().isEmpty ? '—' : (db?.modalities ?? '—');

    return Padding(
      padding: const EdgeInsets.only(bottom: OnisViewerConstants.marginLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Study header
          Padding(
            padding: const EdgeInsets.only(
              bottom: OnisViewerConstants.marginSmall,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: OnisViewerConstants.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Body: $bodyParts',
                  style: const TextStyle(
                    color: OnisViewerConstants.textSecondaryColor,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Mod: $modalities',
                  style: const TextStyle(
                    color: OnisViewerConstants.textSecondaryColor,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Series tiles in a wrap (square areas)
          Wrap(
            spacing: OnisViewerConstants.marginSmall,
            runSpacing: OnisViewerConstants.marginSmall,
            children: [
              for (final series in study.series) _SeriesTile(series: series),
            ],
          ),
        ],
      ),
    );
  }
}

/// Square tile for one series: image + image count badge top-left. Draggable.
class _SeriesTile extends StatelessWidget {
  static const double _tileSize = 72;

  final entities.Series series;

  const _SeriesTile({required this.series});

  @override
  Widget build(BuildContext context) {
    final db = series.databaseInfo;
    final iconPath = db?.iconPath ?? '';
    final imcnt = db?.imcnt ?? 0;
    final showAsUrl =
        iconPath.startsWith('http://') || iconPath.startsWith('https://');

    final tileContent = SizedBox(
      width: _tileSize,
      height: _tileSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Image or placeholder
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: showAsUrl && iconPath.isNotEmpty
                  ? Image.network(
                      iconPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          // Image count at top-left
          Positioned(
            left: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                '$imcnt',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Draggable<entities.Series>(
      data: series,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(4),
        child: Opacity(
          opacity: 0.9,
          child: tileContent,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: tileContent,
      ),
      child: tileContent,
    );
  }

  Widget _placeholder() {
    return Container(
      color: OnisViewerConstants.tabButtonColor,
      child: const Icon(
        Icons.photo_library_outlined,
        color: OnisViewerConstants.textSecondaryColor,
        size: 28,
      ),
    );
  }
}
