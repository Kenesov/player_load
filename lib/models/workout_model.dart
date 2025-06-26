class Workout {
  final String id;
  final String athleteUsername;
  final String title;
  final String description;
  final DateTime date;
  final DateTime? startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final int? rpe; // Rate of Perceived Exertion (1-10)
  final String type; // 'strength', 'cardio', 'flexibility', etc.
  final bool isCompleted; // Mashg'ulot tugallanganmi
  final List<int> athletes; // Athletes array for coach

  Workout({
    required this.id,
    required this.athleteUsername,
    required this.title,
    required this.description,
    required this.date,
    this.startTime,
    this.endTime,
    required this.durationMinutes,
    this.rpe,
    required this.type,
    this.isCompleted = false,
    this.athletes = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'athlete_username': athleteUsername,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'rpe': rpe,
      'type': type,
      'is_completed': isCompleted,
      'athletes': athletes,
    };
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'],
      athleteUsername: json['athlete_username'],
      title: json['title'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time']) : null,
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      durationMinutes: json['duration_minutes'] ?? json['duration'] ?? 0,
      rpe: json['rpe'],
      type: json['type'],
      isCompleted: json['is_completed'] ?? false,
      athletes: List<int>.from(json['athletes'] ?? []),
    );
  }
}
