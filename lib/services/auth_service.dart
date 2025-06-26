import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/athlete_model.dart';
import '../config/api_config.dart';
import 'http_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

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

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // API response structure ni tekshirish
        if (responseData['status'] == 'OK' && responseData['data'] != null) {
          final data = responseData['data'];

          SharedPreferences prefs = await SharedPreferences.getInstance();

          // Null check qo'shish va to'g'ri data extraction
          String? accessTokenRaw = data['access'];
          String? refreshTokenRaw = data['refresh'];
          Map<String, dynamic>? userDataRaw = data['user'];

          if (accessTokenRaw == null || refreshTokenRaw == null || userDataRaw == null) {
            print('Login failed: Missing required data in response');
            return false;
          }

          String accessToken = accessTokenRaw.toString();
          String refreshToken = refreshTokenRaw.toString();
          Map<String, dynamic> userData = Map<String, dynamic>.from(userDataRaw);

          // Profile picture URL ni to'g'ri format qilish
          if (userData['profile_picture'] != null) {
            String profilePicture = userData['profile_picture'].toString();
            if (profilePicture.isNotEmpty && !profilePicture.startsWith('http')) {
              userData['profile_picture'] = 'https://sportrpe.diyarbek.uz$profilePicture';
            }
          }

          // Null safety uchun default values
          userData['first_name'] = userData['first_name']?.toString() ?? '';
          userData['last_name'] = userData['last_name']?.toString() ?? '';
          userData['email'] = userData['email']?.toString() ?? '';
          userData['username'] = userData['username']?.toString() ?? '';
          userData['role'] = userData['role']?.toString() ?? '';
          userData['phone_number'] = userData['phone_number']?.toString();
          userData['bio'] = userData['bio']?.toString();

          if (accessToken.isNotEmpty && refreshToken.isNotEmpty) {
            await prefs.setString('access_token', accessToken);
            await prefs.setString('refresh_token', refreshToken);
            await prefs.setString('user_data', jsonEncode(userData));

            print('Login successful - Access token: ${accessToken.substring(0, 20)}...');
            print('User data saved: $userData');

            return true;
          } else {
            print('Login failed: Empty tokens');
            return false;
          }
        } else {
          print('Login failed: Invalid response structure');
          return false;
        }
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      print('Login error stack trace: ${StackTrace.current}');
      return false;
    }
  }

  Future<bool> registerCoach(Map<String, dynamic> userData) async {
    try {
      // Avval user yaratamiz
      final userResponse = await _httpService.post(
        ApiConfig.register,
        body: {
          ...userData,
          'role': 'COACH',
        },
        includeAuth: false,
      );

      print('Register response status: ${userResponse.statusCode}');
      print('Register response body: ${userResponse.body}');

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

        // Login qilish token olish uchun
        final loginSuccess = await login(userData['username'], userData['password']);

        if (loginSuccess) {
          // Coach profile yaratishni sinab ko'ramiz, agar xato bo'lsa ham davom etamiz
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

            print('Coach profile response: ${coachResponse.statusCode}');
            print('Coach profile body: ${coachResponse.body}');

            // Coach profile yaratilmasa ham, user COACH role bilan yaratilgan bo'lsa muvaffaqiyatli
            if (coachResponse.statusCode == 201 || coachResponse.statusCode == 200) {
              print('Coach profile created successfully');
            } else {
              print('Coach profile creation failed, but user is already created with COACH role');
            }
          } catch (e) {
            print('Coach profile creation error: $e');
            print('Continuing without coach profile...');
          }

          // User COACH role bilan yaratilgan va login muvaffaqiyatli bo'lsa, true qaytaramiz
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userDataString = prefs.getString('user_data');

      if (userDataString != null && userDataString.isNotEmpty) {
        Map<String, dynamic> userData = jsonDecode(userDataString);
        print('Cached user data: $userData');

        // Null safety uchun default values
        userData = Map<String, dynamic>.from(userData);
        userData['first_name'] = userData['first_name'] ?? '';
        userData['last_name'] = userData['last_name'] ?? '';
        userData['email'] = userData['email'] ?? '';
        userData['username'] = userData['username'] ?? '';
        userData['role'] = userData['role'] ?? '';

        return User.fromJson(userData);
      }

      // Agar local da yo'q bo'lsa, API dan olish
      final response = await _httpService.get(ApiConfig.me);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        Map<String, dynamic> userData;
        if (responseData['status'] == 'OK' && responseData['data'] != null) {
          userData = Map<String, dynamic>.from(responseData['data']);
        } else {
          userData = Map<String, dynamic>.from(responseData);
        }

        // Profile picture URL ni to'g'ri format qilish
        if (userData['profile_picture'] != null &&
            userData['profile_picture'].toString().isNotEmpty &&
            !userData['profile_picture'].toString().startsWith('http')) {
          userData['profile_picture'] = 'https://sportrpe.diyarbek.uz${userData['profile_picture']}';
        }

        // Default values qo'shish
        userData['first_name'] = userData['first_name'] ?? '';
        userData['last_name'] = userData['last_name'] ?? '';
        userData['email'] = userData['email'] ?? '';
        userData['username'] = userData['username'] ?? '';
        userData['role'] = userData['role'] ?? '';

        await prefs.setString('user_data', jsonEncode(userData));
        return User.fromJson(userData);
      }

      return null;
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  Future<List<Athlete>> getAthletesByCoach(String coachUsername) async {
    try {
      final response = await _httpService.get(ApiConfig.myAthletes);
      print('My athletes response: ${response.statusCode}');
      print('My athletes body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Response structure ni tekshirish
        List<dynamic> athletesData = [];
        if (responseData['status'] == 'OK' && responseData['data'] != null) {
          athletesData = responseData['data'];
        } else if (responseData is List) {
          athletesData = responseData;
        }

        print('Athletes data: $athletesData');
        return athletesData.map((json) => Athlete.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Get athletes by coach error: $e');
      return [];
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
    String? token = prefs.getString('access_token');
    return token != null && token.isNotEmpty;
  }
}
