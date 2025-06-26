import 'dart:convert';
import '../models/training_session_model.dart';
import '../models/rpe_record_model.dart';
import '../config/api_config.dart';
import 'http_service.dart';

class ApiTrainingService {
  static final ApiTrainingService _instance = ApiTrainingService._internal();
  factory ApiTrainingService() => _instance;
  ApiTrainingService._internal();

  final HttpService _httpService = HttpService();

  Future<List<TrainingSession>> getTrainingSessions() async {
    try {
      final response = await _httpService.get(ApiConfig.trainingSessions);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TrainingSession.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get training sessions error: $e');
      return [];
    }
  }

  Future<bool> createTrainingSession(TrainingSession session) async {
    try {
      final response = await _httpService.post(
        ApiConfig.trainingSessions,
        body: session.toJson(),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Create training session error: $e');
      return false;
    }
  }

  Future<TrainingSession?> getTrainingSessionById(int id) async {
    try {
      final response = await _httpService.get('${ApiConfig.trainingSessions}$id/');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TrainingSession.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Get training session by id error: $e');
      return null;
    }
  }

  Future<List<RPERecord>> getRPERecords() async {
    try {
      final response = await _httpService.get(ApiConfig.rpeRecords);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => RPERecord.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get RPE records error: $e');
      return [];
    }
  }

  Future<bool> createRPERecord(RPERecord record) async {
    try {
      final response = await _httpService.post(
        ApiConfig.rpeRecords,
        body: record.toJson(),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Create RPE record error: $e');
      return false;
    }
  }

  Future<bool> updateRPERecord(int id, RPERecord record) async {
    try {
      final response = await _httpService.patch(
        '${ApiConfig.rpeRecords}$id/',
        body: record.toJson(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Update RPE record error: $e');
      return false;
    }
  }

  // Yangi athlete report endpoint
  Future<Map<String, dynamic>?> getAthleteReport(int athleteId, {
    String period = 'week',
    String? startDate,
    String? endDate,
  }) async {
    try {
      String endpoint = '/api/trainings/athlete-report/$athleteId/';
      List<String> params = [];

      params.add('period=$period');
      if (startDate != null) params.add('start_date=$startDate');
      if (endDate != null) params.add('end_date=$endDate');

      if (params.isNotEmpty) {
        endpoint += '?${params.join('&')}';
      }

      print('Getting athlete report: $endpoint');
      final response = await _httpService.get(endpoint);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'OK' && responseData['data'] != null) {
          return responseData['data'];
        }
      }
      return null;
    } catch (e) {
      print('Get athlete report error: $e');
      return null;
    }
  }

  // Yangi team report endpoint
  Future<List<Map<String, dynamic>>> getTeamReport({
    String period = 'week',
    String? startDate,
    String? endDate,
  }) async {
    try {
      String endpoint = '/api/trainings/team-report/';
      List<String> params = [];

      params.add('period=$period');
      if (startDate != null) params.add('start_date=$startDate');
      if (endDate != null) params.add('end_date=$endDate');

      if (params.isNotEmpty) {
        endpoint += '?${params.join('&')}';
      }

      print('Getting team report: $endpoint');
      final response = await _httpService.get(endpoint);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'OK' && responseData['data'] != null) {
          final List<dynamic> data = responseData['data'];
          return data.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      print('Get team report error: $e');
      return [];
    }
  }
}
