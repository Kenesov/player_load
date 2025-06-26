class RPERecord {
  final int? id;
  final int athleteId;
  final String? athleteName;
  final int trainingSessionId;
  final String? trainingTitle;
  final DateTime? trainingDate;
  final int rpeValue;
  final String? rpeLevel;
  final String? notes;
  final DateTime? recordedAt;
  final int? srpe;

  RPERecord({
    this.id,
    required this.athleteId,
    this.athleteName,
    required this.trainingSessionId,
    this.trainingTitle,
    this.trainingDate,
    required this.rpeValue,
    this.rpeLevel,
    this.notes,
    this.recordedAt,
    this.srpe,
  });

  factory RPERecord.fromJson(Map<String, dynamic> json) {
    return RPERecord(
      id: json['id'],
      athleteId: json['athlete'],
      athleteName: json['athlete_name'],
      trainingSessionId: json['training_session'],
      trainingTitle: json['training_title'],
      trainingDate: json['training_date'] != null
          ? DateTime.parse(json['training_date'])
          : null,
      rpeValue: json['rpe_value'] ?? json['rpe_scale'] ?? 0,
      rpeLevel: json['rpe_level'],
      notes: json['notes'],
      recordedAt: json['recorded_at'] != null
          ? DateTime.parse(json['recorded_at'])
          : null,
      srpe: json['srpe'],
    );
  }

  Map<String, dynamic> toJson() {
    // API rpe_value maydonini kutmoqda
    return {
      'athlete': athleteId,
      'training_session': trainingSessionId,
      'rpe_value': rpeValue, // To'g'ri maydon nomi
      'notes': notes,
    };
  }
}
