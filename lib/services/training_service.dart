import 'dart:convert';
import '../models/training_session_model.dart';
import '../models/rpe_record_model.dart';
import '../config/api_config.dart';
import 'http_service.dart';
import '../models/athlete_model.dart'; // Athlete model import qilindi
// Import qo'shish
import '../models/rpe_scale_model.dart';

class TrainingService {
  static final TrainingService _instance = TrainingService._internal();
  factory TrainingService() => _instance;
  TrainingService._internal();

  final HttpService _httpService = HttpService();

  Future<List<TrainingSession>> getTrainingSessions() async {
    try {
      final response = await _httpService.get(ApiConfig.trainingSessions);
      print('Training sessions response: ${response.statusCode}');
      print('Training sessions body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // API response structure ni tekshirish
        List<dynamic> sessionsData = [];
        if (responseData['status'] == 'OK' && responseData['data'] != null) {
          sessionsData = responseData['data'];
        } else if (responseData is List) {
          sessionsData = responseData;
        }

        return sessionsData.map((json) => TrainingSession.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get training sessions error: $e');
      return [];
    }
  }

  // Athlete uchun training sessions olish - athlete profile ID bilan
  Future<List<TrainingSession>> getTrainingSessionsForAthlete(int athleteProfileId) async {
    try {
      final response = await _httpService.get(ApiConfig.trainingSessions);
      print('Training sessions for athlete response: ${response.statusCode}');
      print('Training sessions for athlete body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        List<dynamic> sessionsData = [];
        if (responseData['status'] == 'OK' && responseData['data'] != null) {
          sessionsData = responseData['data'];
        } else if (responseData is List) {
          sessionsData = responseData;
        }

        final allSessions = sessionsData.map((json) => TrainingSession.fromJson(json)).toList();

        print('All sessions: ${allSessions.length}');
        print('Looking for athlete profile ID: $athleteProfileId');

        // Faqat shu athlete profile ID ga tegishli sessionlarni qaytarish
        final athleteSessions = allSessions.where((session) {
          print('Session ${session.id} athletes: ${session.athleteIds}');
          return session.athleteIds.contains(athleteProfileId);
        }).toList();

        print('Found ${athleteSessions.length} sessions for athlete $athleteProfileId');
        return athleteSessions;
      }
      return [];
    } catch (e) {
      print('Get training sessions for athlete error: $e');
      return [];
    }
  }

  // User ID orqali athlete profile ID ni topish
  Future<int?> getAthleteProfileIdByUserId(int userId) async {
    try {
      final response = await _httpService.get(ApiConfig.athletes);
      print('All athletes response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        List<dynamic> athletesData = [];
        if (responseData['status'] == 'OK' && responseData['data'] != null) {
          athletesData = responseData['data'];
        } else if (responseData is List) {
          athletesData = responseData;
        }

        // User ID ga mos athlete topish
        for (var athleteJson in athletesData) {
          final athlete = Athlete.fromJson(athleteJson);
          if (athlete.user.id == userId) {
            print('Found athlete profile ID ${athlete.id} for user ID $userId');
            return athlete.id;
          }
        }
      }
      return null;
    } catch (e) {
      print('Get athlete profile ID by user ID error: $e');
      return null;
    }
  }

  Future<bool> createTrainingSession(TrainingSession session) async {
    try {
      // JSON format ishlatish chunki athletes array bor
      final response = await _httpService.post(
        ApiConfig.trainingSessions,
        body: session.toJson(),
        forceJson: true, // JSON formatni majburlash
      );
      print('Create training session response: ${response.statusCode}');
      print('Create training session body: ${response.body}');

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Create training session error: $e');
      return false;
    }
  }

  Future<List<RPERecord>> getRPERecords() async {
    try {
      final response = await _httpService.get(ApiConfig.rpeRecords);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        List<dynamic> recordsData = [];
        if (responseData['status'] == 'OK' && responseData['data'] != null) {
          recordsData = responseData['data'];
        } else if (responseData is List) {
          recordsData = responseData;
        }

        return recordsData.map((json) => RPERecord.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get RPE records error: $e');
      return [];
    }
  }

  // Athlete uchun RPE records olish - athlete profile ID bilan
  Future<List<RPERecord>> getRPERecordsForAthlete(int athleteProfileId) async {
    try {
      final response = await _httpService.get(ApiConfig.rpeRecords);
      print('RPE records for athlete response: ${response.statusCode}');
      print('RPE records for athlete body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        List<dynamic> recordsData = [];
        if (responseData['status'] == 'OK' && responseData['data'] != null) {
          recordsData = responseData['data'];
        } else if (responseData is List) {
          recordsData = responseData;
        }

        final allRecords = recordsData.map((json) => RPERecord.fromJson(json)).toList();

        print('All RPE records: ${allRecords.length}');
        print('Looking for athlete profile ID: $athleteProfileId');

        // Faqat shu athlete profile ID ga tegishli recordlarni qaytarish
        final athleteRecords = allRecords.where((record) {
          print('Record athlete ID: ${record.athleteId}');
          return record.athleteId == athleteProfileId;
        }).toList();

        print('Found ${athleteRecords.length} RPE records for athlete $athleteProfileId');
        return athleteRecords;
      }
      return [];
    } catch (e) {
      print('Get RPE records for athlete error: $e');
      return [];
    }
  }

  Future<bool> createRPERecord(RPERecord record) async {
    try {
      final response = await _httpService.post(
        ApiConfig.rpeRecords,
        body: record.toJson(),
        forceJson: true,
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Create RPE record error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getAthleteReport(int athleteId, {
    String period = 'week',
    String? startDate,
    String? endDate,
  }) async {
    try {
      String endpoint = '${ApiConfig.athleteReport}$athleteId/?period=$period';
      if (startDate != null) endpoint += '&start_date=$startDate';
      if (endDate != null) endpoint += '&end_date=$endDate';

      final response = await _httpService.get(endpoint);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 'OK' && responseData['data'] != null) {
          return responseData['data'];
        }
        return responseData;
      }
      return null;
    } catch (e) {
      print('Get athlete report error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getTeamReport({
    String period = 'week',
    String? startDate,
    String? endDate,
  }) async {
    try {
      String endpoint = '${ApiConfig.teamReport}?period=$period';
      if (startDate != null) endpoint += '&start_date=$startDate';
      if (endDate != null) endpoint += '&end_date=$endDate';

      final response = await _httpService.get(endpoint);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        List<dynamic> reportsData = [];
        if (responseData['status'] == 'OK' && responseData['data'] != null) {
          reportsData = responseData['data'];
        } else if (responseData is List) {
          reportsData = responseData;
        }

        return reportsData.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Get team report error: $e');
      return [];
    }
  }

  // RPE scales olish methodi qo'shish
  Future<List<RPEScale>> getRPEScales() async {
    try {
      final response = await _httpService.get(ApiConfig.rpeScales);
      print('RPE scales response: ${response.statusCode}');
      print('RPE scales body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        List<dynamic> scalesData = [];
        if (responseData['status'] == 'OK' && responseData['data'] != null) {
          scalesData = responseData['data'];
        } else if (responseData is List) {
          scalesData = responseData;
        }

        return scalesData.map((json) => RPEScale.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get RPE scales error: $e');
      return [];
    }
  }
  HttpService get httpService => _httpService;
}
