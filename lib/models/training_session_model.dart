class TrainingSession {
  final int id;
  final String title;
  final String? description;
  final DateTime date;
  final String startTime; // "HH:MM" format
  final String endTime; // "HH:MM" format
  final int durationMinutes;
  final int coachId;
  final List<int> athleteIds;

  TrainingSession({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.coachId,
    required this.athleteIds,
  });

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    return TrainingSession(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      startTime: json['start_time'],
      endTime: json['end_time'],
      durationMinutes: json['duration_minutes'],
      coachId: json['coach'],
      athleteIds: List<int>.from(json['athletes'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'date': date.toIso8601String().split('T')[0],
      'start_time': startTime,
      'end_time': endTime,
      'duration_minutes': durationMinutes,
      'coach': coachId,
      'athletes': athleteIds,
    };
  }
}
