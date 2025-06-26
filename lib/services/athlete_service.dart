import 'dart:convert';
import '../models/athlete_model.dart';
import '../config/api_config.dart';
import 'http_service.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'image_service.dart';

class AthleteService {
  static final AthleteService _instance = AthleteService._internal();
  factory AthleteService() => _instance;
  AthleteService._internal();

  final HttpService _httpService = HttpService();

  Future<List<Athlete>> getAthletes() async {
    try {
      final response = await _httpService.get(ApiConfig.athletes);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        List<dynamic> athletesData = [];
        if (responseData['status'] == 'OK' && responseData['data'] != null) {
          athletesData = responseData['data'];
        } else if (responseData is List) {
          athletesData = responseData;
        }

        return athletesData.map((json) => Athlete.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get athletes error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createAthlete(Map<String, dynamic> userData, Map<String, dynamic> athleteData, {File? profileImage}) async {
    try {
      // Avval user yaratamiz
      http.Response userResponse;

      if (profileImage != null) {
        // Rasmni tayyorlash
        print('Preparing athlete profile image...');
        File? preparedImage = await ImageService().prepareProfileImage(profileImage);

        if (preparedImage == null) {
          return {'success': false, 'message': 'Rasmni tayyorlashda xatolik yuz berdi'};
        }

        // Rasm bilan user yaratish
        var userRequest = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.register}'),
        );

        // User ma'lumotlarini qo'shish
        userData.forEach((key, value) {
          if (value != null) {
            userRequest.fields[key] = value.toString();
          }
        });
        userRequest.fields['role'] = 'ATHLETE';

        // Tayyorlangan profile picture qo'shish
        userRequest.files.add(
          await http.MultipartFile.fromPath(
            'profile_picture',
            preparedImage.path,
            filename: 'profile.jpg',
          ),
        );

        final userStreamedResponse = await userRequest.send();
        userResponse = await http.Response.fromStream(userStreamedResponse);

        // Vaqtinchalik faylni o'chirish
        try {
          await preparedImage.delete();
        } catch (e) {
          print('Failed to delete temp file: $e');
        }
      } else {
        // Rasmsiz user yaratish
        userResponse = await _httpService.post(
          ApiConfig.register,
          body: {
            ...userData,
            'role': 'ATHLETE',
          },
        );
      }

      print('Create athlete user response: ${userResponse.statusCode}');
      print('Create athlete user body: ${userResponse.body}');

      if (userResponse.statusCode == 201 || userResponse.statusCode == 200) {
        final responseData = jsonDecode(userResponse.body);

        // Response structure ni to'g'ri parse qilish
        Map<String, dynamic> user;
        if (responseData['status'] == 'Created' && responseData['data'] != null) {
          user = responseData['data'];
        } else if (responseData['status'] == 'OK' && responseData['data'] != null) {
          user = responseData['data'];
        } else {
          user = responseData;
        }

        // User ID ni to'g'ri olish va tekshirish
        dynamic userIdValue = user['id'];
        int userId;

        if (userIdValue is int) {
          userId = userIdValue;
        } else if (userIdValue is String) {
          userId = int.parse(userIdValue);
        } else {
          print('Invalid user ID: $userIdValue');
          return {'success': false, 'message': 'User ID olishda xatolik'};
        }

        print('Parsed User ID: $userId (type: ${userId.runtimeType})');

        // Keyin athlete profile yaratamiz - JSON format ishlatish
        final athleteRequestBody = {
          'user_id': userId, // Integer sifatida yuborish
          ...athleteData,
        };

        print('Athlete request body: $athleteRequestBody');

        final athleteResponse = await _httpService.post(
          ApiConfig.athletes,
          body: athleteRequestBody,
          forceJson: true, // JSON formatni majburlash
        );

        print('Create athlete profile response: ${athleteResponse.statusCode}');
        print('Create athlete profile body: ${athleteResponse.body}');

        if (athleteResponse.statusCode == 201 || athleteResponse.statusCode == 200) {
          return {'success': true, 'message': 'Sportchi muvaffaqiyatli qo\'shildi!'};
        } else {
          final athleteErrorData = jsonDecode(athleteResponse.body);
          String errorMessage = 'Sportchi profili yaratishda xatolik';

          if (athleteErrorData['errors'] != null) {
            final errors = athleteErrorData['errors'] as Map<String, dynamic>;
            errorMessage = errors.values.first.toString().replaceAll('[', '').replaceAll(']', '');
          } else if (athleteErrorData['message'] != null) {
            errorMessage = athleteErrorData['message'];
          }

          print('Athlete creation error: $errorMessage');
          return {'success': false, 'message': errorMessage};
        }
      } else {
        // User yaratishda xatolik
        final errorData = jsonDecode(userResponse.body);
        String errorMessage = 'Foydalanuvchi yaratishda xatolik';

        if (errorData['errors'] != null) {
          final errors = errorData['errors'] as Map<String, dynamic>;
          if (errors['username'] != null) {
            errorMessage = 'Bu username allaqachon mavjud. Boshqa username tanlang.';
          } else if (errors['email'] != null) {
            errorMessage = 'Bu email allaqachon mavjud. Boshqa email tanlang.';
          } else {
            errorMessage = errors.values.first.toString().replaceAll('[', '').replaceAll(']', '');
          }
        }

        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      print('Create athlete error: $e');
      return {'success': false, 'message': 'Tarmoq xatoligi: $e'};
    }
  }

  Future<Athlete?> getAthleteById(int id) async {
    try {
      final response = await _httpService.get('${ApiConfig.athletes}$id/');
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        Map<String, dynamic> athleteData;
        if (responseData['status'] == 'OK' && responseData['data'] != null) {
          athleteData = responseData['data'];
        } else {
          athleteData = responseData;
        }

        return Athlete.fromJson(athleteData);
      }
      return null;
    } catch (e) {
      print('Get athlete by id error: $e');
      return null;
    }
  }

  // Joriy user ma'lumotlarini olish (/api/users/me/ dan)
  Future<Athlete?> getMyProfile() async {
    try {
      final response = await _httpService.get(ApiConfig.me);
      print('My profile response: ${response.statusCode}');
      print('My profile body: ${response.body}');

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        print('User data: $userData');

        // User ma'lumotlaridan athlete ma'lumotlarini qidirish
        final userId = userData['id'];
        if (userId != null) {
          return await getAthleteByUserId(userId);
        }
      }
      return null;
    } catch (e) {
      print('Get my profile error: $e');
      return null;
    }
  }

  Future<Athlete?> getAthleteByUserId(int userId) async {
    try {
      final response = await _httpService.get('${ApiConfig.athletes}?user_id=$userId');
      print('Athlete by user ID response: ${response.statusCode}');
      print('Athlete by user ID body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        List<dynamic> athletesData = [];
        if (responseData['status'] == 'OK' && responseData['data'] != null) {
          athletesData = responseData['data'];
        } else if (responseData is List) {
          athletesData = responseData;
        }

        if (athletesData.isNotEmpty) {
          return Athlete.fromJson(athletesData.first);
        }
      }
      return null;
    } catch (e) {
      print('Get athlete by user ID error: $e');
      return null;
    }
  }

  Future<bool> updateAthlete(int id, Map<String, dynamic> athleteData) async {
    try {
      final response = await _httpService.patch(
        '${ApiConfig.athletes}$id/',
        body: athleteData,
        forceJson: true,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Update athlete error: $e');
      return false;
    }
  }
}
