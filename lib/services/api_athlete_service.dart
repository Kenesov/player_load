import 'dart:convert';
import '../models/athlete_model.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';
import 'http_service.dart';

class ApiAthleteService {
  static final ApiAthleteService _instance = ApiAthleteService._internal();
  factory ApiAthleteService() => _instance;
  ApiAthleteService._internal();

  final HttpService _httpService = HttpService();

  Future<List<Athlete>> getAthletes() async {
    try {
      final response = await _httpService.get(ApiConfig.athletes);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Athlete.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get athletes error: $e');
      return [];
    }
  }

  Future<List<Athlete>> getMyAthletes() async {
    try {
      final response = await _httpService.get(ApiConfig.myAthletes);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // API response structure ga qarab o'zgartirish kerak bo'lishi mumkin
        return [];
      }
      return [];
    } catch (e) {
      print('Get my athletes error: $e');
      return [];
    }
  }

  Future<bool> createAthlete(Map<String, dynamic> userData, Map<String, dynamic> athleteData) async {
    try {
      // Avval user yaratamiz
      final userResponse = await _httpService.post(
        ApiConfig.register,
        body: {
          ...userData,
          'role': 'ATHLETE',
        },
      );

      if (userResponse.statusCode == 201) {
        final user = jsonDecode(userResponse.body);

        // Keyin athlete profile yaratamiz
        final athleteResponse = await _httpService.post(
          ApiConfig.athletes,
          body: {
            'user_id': user['id'],
            ...athleteData,
          },
        );

        return athleteResponse.statusCode == 201;
      }
      return false;
    } catch (e) {
      print('Create athlete error: $e');
      return false;
    }
  }

  Future<Athlete?> getAthleteById(int id) async {
    try {
      final response = await _httpService.get('${ApiConfig.athletes}$id/');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Athlete.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Get athlete by id error: $e');
      return null;
    }
  }

  Future<bool> updateAthlete(int id, Map<String, dynamic> athleteData) async {
    try {
      final response = await _httpService.patch(
        '${ApiConfig.athletes}$id/',
        body: athleteData,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Update athlete error: $e');
      return false;
    }
  }
}
