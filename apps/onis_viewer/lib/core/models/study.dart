/// Study model for database management
class Study {
  final String id;
  final String name;
  final String sex;
  final DateTime birthDate;
  final String? patientId;
  final String? studyDate;
  final String? modality;
  final String? status;

  const Study({
    required this.id,
    required this.name,
    required this.sex,
    required this.birthDate,
    this.patientId,
    this.studyDate,
    this.modality,
    this.status,
  });

  /// Create a Study from a map (for JSON deserialization)
  factory Study.fromMap(Map<String, dynamic> map) {
    return Study(
      id: map['id'] as String,
      name: map['name'] as String,
      sex: map['sex'] as String,
      birthDate: DateTime.parse(map['birthDate'] as String),
      patientId: map['patientId'] as String?,
      studyDate: map['studyDate'] as String?,
      modality: map['modality'] as String?,
      status: map['status'] as String?,
    );
  }

  /// Convert Study to a map (for JSON serialization)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sex': sex,
      'birthDate': birthDate.toIso8601String(),
      'patientId': patientId,
      'studyDate': studyDate,
      'modality': modality,
      'status': status,
    };
  }

  /// Create a copy of this Study with updated fields
  Study copyWith({
    String? id,
    String? name,
    String? sex,
    DateTime? birthDate,
    String? patientId,
    String? studyDate,
    String? modality,
    String? status,
  }) {
    return Study(
      id: id ?? this.id,
      name: name ?? this.name,
      sex: sex ?? this.sex,
      birthDate: birthDate ?? this.birthDate,
      patientId: patientId ?? this.patientId,
      studyDate: studyDate ?? this.studyDate,
      modality: modality ?? this.modality,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Study && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Study(id: $id, name: $name, sex: $sex, birthDate: $birthDate)';
  }
}
