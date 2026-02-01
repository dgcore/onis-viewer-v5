import 'package:onis_viewer/core/error_codes.dart';
import 'package:onis_viewer/core/models/database/patient.dart' as database;
import 'package:onis_viewer/core/models/database/study.dart' as database;
import 'package:onis_viewer/core/onis_exception.dart';

class FindPatientStudySourceResponse {
  final String sourceUid;
  final int status;
  final bool haveConflicts;
  final List<({database.Patient patient, database.Study study})> studies;

  FindPatientStudySourceResponse({
    required this.sourceUid,
    required this.status,
    required this.haveConflicts,
    required this.studies,
  });

  static FindPatientStudySourceResponse fromJson(
      String sourceUid, Map<String, dynamic> json) {
    try {
      int status = json['status'] as int;
      bool haveConflicts = false; //json['haveConflicts'] as bool;
      List<({database.Patient patient, database.Study study})> studies = [];
      if (status == OnisErrorCodes.none) {
        json['studies'].forEach((item) {
          database.Patient patient = database.Patient.fromJson(item["patient"]);
          database.Study study = database.Study.fromJson(item["study"]);
          patient.sourceUid = sourceUid;
          study.sourceUid = sourceUid;
          studies.add((patient: patient, study: study));
        });
      }
      return FindPatientStudySourceResponse(
        sourceUid: sourceUid,
        status: status,
        haveConflicts: haveConflicts,
        studies: studies,
      );
    } catch (e) {
      return FindPatientStudySourceResponse(
        sourceUid: sourceUid,
        status: OnisErrorCodes.invalidResponse,
        haveConflicts: false,
        studies: [],
      );
    }
  }
}

class FindPatientStudyResponse {
  String sourceUid;
  int status;
  final List<FindPatientStudySourceResponse> sources;

  FindPatientStudyResponse({
    required this.sourceUid,
    required this.status,
    required this.sources,
  });

  static FindPatientStudyResponse fromJson(
      String sourceUid, Map<String, dynamic> json) {
    try {
      List<FindPatientStudySourceResponse> sources = [];
      final sourcesMap = json["sources"] as Map<String, dynamic>;
      for (final entry in sourcesMap.entries) {
        final sourceKey = entry.key;
        final sourceValue = entry.value as Map<String, dynamic>;
        sources.add(
            FindPatientStudySourceResponse.fromJson(sourceKey, sourceValue));
      }
      return FindPatientStudyResponse(
        sourceUid: sourceUid,
        status: OnisErrorCodes.none,
        sources: sources,
      );
    } on OnisException catch (e) {
      return FindPatientStudyResponse(
        sourceUid: sourceUid,
        status: e.code,
        sources: [],
      );
    } catch (e) {
      return FindPatientStudyResponse(
        sourceUid: sourceUid,
        status: OnisErrorCodes.invalidResponse,
        sources: [],
      );
    }
  }
}
