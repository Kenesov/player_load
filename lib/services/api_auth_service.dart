import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../config/api_config.dart';
import 'http_service.dart';
import 'auth_service.dart';
import 'image_service.dart';

class ApiAuthService {
  static final ApiAuthService _instance = ApiAuthService._internal();
  factory ApiAuthService() => _instance;
  ApiAuthService._internal();

  final HttpService _httpService = HttpService();

  Future<bool> login(String username, String password) async {
    try {
      final response = await _httpService.post(
        ApiConfig.login,
        body: {
          'username': username,
          'password': password,
        },
        includeAuth: false,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access']);
        await prefs.setString('refresh_token', data['refresh']);
        await prefs.setString('user_data', jsonEncode(data['user']));

        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> registerCoach(Map<String, dynamic> userData) async {
    try {
      // Avval user yaratamiz - bu endpoint authentication talab qilmaydi
      final userResponse = await _httpService.post(
        ApiConfig.register, // Bu /api/users/users/ endpoint
        body: {
          ...userData,
          'role': 'COACH',
        },
        includeAuth: false, // Authentication talab qilmaydi
      );

      print('User creation response: ${userResponse.statusCode}');
      print('User creation body: ${userResponse.body}');

      if (userResponse.statusCode == 201) {
        final responseData = jsonDecode(userResponse.body);

        // User ma'lumotlarini olish
        Map<String, dynamic> user;
        if (responseData['status'] == 'Created' && responseData['data'] != null) {
          user = responseData['data'];
        } else {
          user = responseData;
        }

        // Login qilish - token olish uchun
        final loginSuccess = await login(userData['username'], userData['password']);

        if (loginSuccess) {
          // Coach profile yaratishni sinab ko'ramiz, lekin majburiy emas
          try {
            final coachResponse = await _httpService.post(
              ApiConfig.coaches,
              body: {
                'user_id': user['id'],
                'certification': null,
                'institution': null,
              },
              includeAuth: true, // Authentication kerak
            );

            print('Coach creation response: ${coachResponse.statusCode}');
            print('Coach creation body: ${coachResponse.body}');

            // Coach profile yaratilmasa ham, user COACH role bilan yaratilgan
            return true;
          } catch (e) {
            print('Coach profile creation failed, but user is created: $e');
            return true; // User yaratilgan, coach profile yaratilmasa ham muvaffaqiyatli
          }
        }
      }
      return false;
    } catch (e) {
      print('Register coach error: $e');
      return false;
    }
  }

  Future<bool> registerCoachWithImage(Map<String, dynamic> userData, File profileImage) async {
    try {
      // Rasmni tayyorlash (siqish va o'lchamini kichraytirish)
      print('Preparing profile image...');
      File? preparedImage = await ImageService().prepareProfileImage(profileImage);

      if (preparedImage == null) {
        print('Failed to prepare image');
        return false;
      }

      // Tayyorlangan rasm hajmini tekshirish
      int imageSize = await preparedImage.length();
      print('Prepared image size: ${ImageService().formatFileSize(imageSize)}');

      // User yaratish uchun multipart request
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
      userRequest.fields['role'] = 'COACH';

      // Tayyorlangan profile picture qo'shish
      userRequest.files.add(
        await http.MultipartFile.fromPath(
          'profile_picture',
          preparedImage.path,
          filename: 'profile.jpg', // JPEG formatini ko'rsatish
        ),
      );

      print('Sending registration request with image size: ${ImageService().formatFileSize(imageSize)}');

      final userStreamedResponse = await userRequest.send();
      final userResponse = await http.Response.fromStream(userStreamedResponse);

      print('User with image creation response: ${userResponse.statusCode}');
      print('User with image creation body: ${userResponse.body}');

      // Vaqtinchalik faylni o'chirish
      try {
        await preparedImage.delete();
      } catch (e) {
        print('Failed to delete temp file: $e');
      }

      if (userResponse.statusCode == 201) {
        final responseData = jsonDecode(userResponse.body);

        Map<String, dynamic> user;
        if (responseData['status'] == 'Created' && responseData['data'] != null) {
          user = responseData['data'];
        } else {
          user = responseData;
        }

        // Login qilish - AuthService dan foydalanish
        final loginSuccess = await AuthService().login(
            userData['username']?.toString() ?? '',
            userData['password']?.toString() ?? ''
        );

        if (loginSuccess) {
          // Coach profile yaratishni sinab ko'ramiz, lekin majburiy emas
          try {
            final coachResponse = await _httpService.post(
              ApiConfig.coaches,
              body: {
                'user_id': user['id'],
                'certification': null,
                'institution': null,
              },
              includeAuth: true,
            );

            print('Coach profile creation response: ${coachResponse.statusCode}');
            print('Coach profile creation body: ${coachResponse.body}');
          } catch (e) {
            print('Coach profile creation failed, but user is created: $e');
          }

          // User COACH role bilan yaratilgan va login muvaffaqiyatli bo'lsa true qaytaramiz
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Register with image error: $e');
      print('Register with image stack trace: ${StackTrace.current}');
      return false;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userDataString = prefs.getString('user_data');

      if (userDataString != null) {
        Map<String, dynamic> userData = jsonDecode(userDataString);
        return User.fromJson(userData);
      }

      // Agar local da yo'q bo'lsa, API dan olish
      final response = await _httpService.get(ApiConfig.me);
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        await prefs.setString('user_data', jsonEncode(userData));
        return User.fromJson(userData);
      }

      return null;
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  Future<bool> updateUser(int userId, Map<String, dynamic> userData, {File? profilePicture}) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');

      if (token == null) return false;

      var request = http.MultipartRequest(
        'PATCH',
        Uri.parse('${ApiConfig.baseUrl}/api/users/users/$userId/'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Text fieldlarni qo'shish
      userData.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });

      // Rasm qo'shish
      if (profilePicture != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_picture',
            profilePicture.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Local storage ni yangilash
        final updatedUser = jsonDecode(response.body);
        await prefs.setString('user_data', jsonEncode(updatedUser));
        return true;
      }

      return false;
    } catch (e) {
      print('Update user error: $e');
      return false;
    }
  }

  Future<bool> refreshToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null) return false;

      final response = await _httpService.post(
        ApiConfig.tokenRefresh,
        body: {'refresh': refreshToken},
        includeAuth: false,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString('access_token', data['access']);
        return true;
      }
      return false;
    } catch (e) {
      print('Refresh token error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_data');
  }

  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') != null;
  }
}
