import 'user_model.dart';

class Athlete {
  final int id;
  final User user;
  final int? coachId;
  final String? coachName;
  final int? age;
  final String? gender;
  final double? weight;
  final double? height;
  final String? sport;
  final String? team;

  Athlete({
    required this.id,
    required this.user,
    this.coachId,
    this.coachName,
    this.age,
    this.gender,
    this.weight,
    this.height,
    this.sport,
    this.team,
  });

  factory Athlete.fromJson(Map<String, dynamic> json) {
    return Athlete(
      id: json['id'] ?? 0,
      user: User.fromJson(json['user'] ?? {}),
      coachId: json['coach'],
      coachName: json['coach_name'],
      age: json['age'] != null ? int.tryParse(json['age'].toString()) : null,
      gender: json['gender'],
      weight: json['weight'] != null ? double.tryParse(json['weight'].toString()) : null,
      height: json['height'] != null ? double.tryParse(json['height'].toString()) : null,
      sport: json['sport'],
      team: json['team'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': user.id,
      'coach': coachId,
      'age': age,
      'gender': gender,
      'weight': weight,
      'height': height,
      'sport': sport,
      'team': team,
    };
  }
}
