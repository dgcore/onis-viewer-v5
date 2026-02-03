import '../../../../core/ui/column_configuration.dart';

/// Default column configuration for the database study/patient table
/// 
/// This provides the default configuration for the database table.
/// Applications can load/save custom configurations using ColumnConfigurationList.
class DatabaseTableColumnConfig {
  /// Create the default column configuration for the database table
  static ColumnConfigurationList createDefault() {
    return ColumnConfigurationList(
      columns: [
        ColumnConfiguration(
          id: 'source',
          title: 'Source',
          isNumeric: false,
          width: 120.0,
          order: 0,
        ),
        ColumnConfiguration(
          id: 'patientId',
          title: 'Patient ID',
          isNumeric: false,
          width: 120.0,
          order: 1,
        ),
        ColumnConfiguration(
          id: 'patientName',
          title: 'Patient Name',
          isNumeric: false,
          width: 200.0,
          order: 2,
        ),
        ColumnConfiguration(
          id: 'birthDate',
          title: 'Birth Date',
          isNumeric: false,
          width: 120.0,
          order: 3,
        ),
        ColumnConfiguration(
          id: 'sex',
          title: 'Sex',
          isNumeric: false,
          width: 80.0,
          order: 4,
        ),
        ColumnConfiguration(
          id: 'age',
          title: 'Age',
          isNumeric: false,
          width: 80.0,
          order: 5,
        ),
        ColumnConfiguration(
          id: 'modalities',
          title: 'Modalities',
          isNumeric: false,
          width: 100.0,
          order: 6,
        ),
        ColumnConfiguration(
          id: 'studyDate',
          title: 'Study Date',
          isNumeric: false,
          width: 120.0,
          order: 7,
        ),
        ColumnConfiguration(
          id: 'studyTime',
          title: 'Study Time',
          isNumeric: false,
          width: 100.0,
          order: 8,
        ),
        ColumnConfiguration(
          id: 'bodyParts',
          title: 'Body Parts',
          isNumeric: false,
          width: 120.0,
          order: 9,
        ),
        ColumnConfiguration(
          id: 'accnum',
          title: 'Accession Number',
          isNumeric: false,
          width: 120.0,
          order: 10,
        ),
        ColumnConfiguration(
          id: 'studyId',
          title: 'Study ID',
          isNumeric: false,
          width: 120.0,
          order: 11,
        ),
        ColumnConfiguration(
          id: 'description',
          title: 'Description',
          isNumeric: false,
          width: 200.0,
          order: 12,
        ),
        ColumnConfiguration(
          id: 'instanceNumber',
          title: 'Instance Number',
          isNumeric: true,
          width: 100.0,
          order: 13,
        ),
        ColumnConfiguration(
          id: 'comment',
          title: 'Comment',
          isNumeric: false,
          width: 150.0,
          order: 14,
        ),
        ColumnConfiguration(
          id: 'stations',
          title: 'Stations',
          isNumeric: false,
          width: 120.0,
          order: 15,
        ),
        ColumnConfiguration(
          id: 'seriesCount',
          title: 'Series',
          isNumeric: true,
          width: 100.0,
          order: 16,
        ),
        ColumnConfiguration(
          id: 'imagesCount',
          title: 'Images',
          isNumeric: true,
          width: 100.0,
          order: 17,
        ),
        ColumnConfiguration(
          id: 'reportsCount',
          title: 'Reports',
          isNumeric: true,
          width: 100.0,
          order: 18,
        ),
        ColumnConfiguration(
          id: 'status',
          title: 'Status',
          isNumeric: false,
          width: 100.0,
          order: 19,
        ),
      ],
    );
  }
}

