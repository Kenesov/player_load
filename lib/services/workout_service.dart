import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_model.dart';

class WorkoutService {
  static final WorkoutService _instance = WorkoutService._internal();
  factory WorkoutService() => _instance;
  WorkoutService._internal();

  Future<List<Workout>> getWorkoutsByAthlete(String athleteUsername) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? workoutsJson = prefs.getString('workouts');

    List<Workout> workouts = [];

    // Demo workouts
    List<Map<String, dynamic>> demoWorkouts = [
      {
        'id': '1',
        'athlete_username': 'athlete1',
        'title': 'Kuch mashg\'uloti',
        'description': 'Yuqori tana kuch mashg\'uloti',
        'date': DateTime.now().add(Duration(days: 1)).toIso8601String(),
        'start_time': DateTime.now().add(Duration(days: 1, hours: 10)).toIso8601String(),
        'end_time': DateTime.now().add(Duration(days: 1, hours: 11)).toIso8601String(),
        'duration_minutes': 60,
        'rpe': null,
        'type': 'strength',
        'is_completed': false,
        'athletes': [1],
      },
      {
        'id': '2',
        'athlete_username': 'athlete1',
        'title': 'Kardio mashg\'uloti',
        'description': '30 daqiqa yugurish',
        'date': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
        'start_time': DateTime.now().subtract(Duration(days: 1, hours: -9)).toIso8601String(),
        'end_time': DateTime.now().subtract(Duration(days: 1, hours: -8, minutes: -30)).toIso8601String(),
        'duration_minutes': 30,
        'rpe': 7,
        'type': 'cardio',
        'is_completed': true,
        'athletes': [1],
      },
    ];

    for (var workoutData in demoWorkouts) {
      if (workoutData['athlete_username'] == athleteUsername) {
        workouts.add(Workout.fromJson(workoutData));
      }
    }

    if (workoutsJson != null) {
      List<dynamic> savedWorkouts = jsonDecode(workoutsJson);
      for (var workoutData in savedWorkouts) {
        Workout workout = Workout.fromJson(workoutData);
        if (workout.athleteUsername == athleteUsername) {
          workouts.add(workout);
        }
      }
    }

    workouts.sort((a, b) => b.date.compareTo(a.date));
    return workouts;
  }

  Future<List<Workout>> getAllWorkouts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? workoutsJson = prefs.getString('workouts');

    List<Workout> workouts = [];

    // Demo workouts
    List<Map<String, dynamic>> demoWorkouts = [
      {
        'id': '1',
        'athlete_username': 'athlete1',
        'title': 'Kuch mashg\'uloti',
        'description': 'Yuqori tana kuch mashg\'uloti',
        'date': DateTime.now().add(Duration(days: 1)).toIso8601String(),
        'start_time': DateTime.now().add(Duration(days: 1, hours: 10)).toIso8601String(),
        'end_time': DateTime.now().add(Duration(days: 1, hours: 11)).toIso8601String(),
        'duration_minutes': 60,
        'rpe': null,
        'type': 'strength',
        'is_completed': false,
        'athletes': [1],
      },
      {
        'id': '2',
        'athlete_username': 'athlete1',
        'title': 'Kardio mashg\'uloti',
        'description': '30 daqiqa yugurish',
        'date': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
        'start_time': DateTime.now().subtract(Duration(days: 1, hours: -9)).toIso8601String(),
        'end_time': DateTime.now().subtract(Duration(days: 1, hours: -8, minutes: -30)).toIso8601String(),
        'duration_minutes': 30,
        'rpe': 7,
        'type': 'cardio',
        'is_completed': true,
        'athletes': [1],
      },
    ];

    for (var workoutData in demoWorkouts) {
      workouts.add(Workout.fromJson(workoutData));
    }

    if (workoutsJson != null) {
      List<dynamic> savedWorkouts = jsonDecode(workoutsJson);
      for (var workoutData in savedWorkouts) {
        workouts.add(Workout.fromJson(workoutData));
      }
    }

    workouts.sort((a, b) => b.date.compareTo(a.date));
    return workouts;
  }

  Future<void> addWorkout(Workout workout) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? workoutsJson = prefs.getString('workouts');

    List<dynamic> workouts = [];
    if (workoutsJson != null) {
      workouts = jsonDecode(workoutsJson);
    }

    workouts.add(workout.toJson());
    await prefs.setString('workouts', jsonEncode(workouts));
  }

  Future<void> updateWorkoutRPE(String workoutId, int rpe) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? workoutsJson = prefs.getString('workouts');

    if (workoutsJson != null) {
      List<dynamic> workouts = jsonDecode(workoutsJson);
      for (int i = 0; i < workouts.length; i++) {
        if (workouts[i]['id'] == workoutId) {
          workouts[i]['rpe'] = rpe;
          break;
        }
      }
      await prefs.setString('workouts', jsonEncode(workouts));
    }
  }

  Future<void> completeWorkout(String workoutId, int rpe) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? workoutsJson = prefs.getString('workouts');

    List<dynamic> workouts = [];
    if (workoutsJson != null) {
      workouts = jsonDecode(workoutsJson);
      for (int i = 0; i < workouts.length; i++) {
        if (workouts[i]['id'] == workoutId) {
          workouts[i]['is_completed'] = true;
          workouts[i]['rpe'] = rpe;
          break;
        }
      }
      await prefs.setString('workouts', jsonEncode(workouts));
    }
  }

  Future<List<Workout>> getUpcomingWorkouts(String athleteUsername) async {
    List<Workout> allWorkouts = await getWorkoutsByAthlete(athleteUsername);
    return allWorkouts.where((workout) => !workout.isCompleted).toList();
  }

  Future<List<Workout>> getCompletedWorkouts(String athleteUsername) async {
    List<Workout> allWorkouts = await getWorkoutsByAthlete(athleteUsername);
    return allWorkouts.where((workout) => workout.isCompleted).toList();
  }
}
