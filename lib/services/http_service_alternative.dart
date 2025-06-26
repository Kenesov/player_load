import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class HttpService {
  static final HttpService _instance = HttpService._internal();
  factory HttpService() => _instance;
  HttpService._internal();

  Future<Map<String, String>> _getHeaders({bool includeAuth = true, bool isFormData = false}) async {
    Map<String, String> headers = {};

    if (isFormData) {
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
    } else {
      headers['Content-Type'] = 'application/json';
    }

    headers['Accept'] = 'application/json';

    if (includeAuth) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<http.Response> post(String endpoint, {
    required Map<String, dynamic> body,
    bool includeAuth = true,
    bool useFormData = false,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth, isFormData: useFormData);
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      print('POST Request: $uri');
      print('Headers: $headers');

      http.Response response;

      if (useFormData) {
        // Form data sifatida yuborish
        final formData = body.map((key, value) => MapEntry(key, value.toString()));
        print('Form Data: $formData');
        response = await http.post(uri, headers: headers, body: formData);
      } else {
        // JSON sifatida yuborish
        final jsonBody = jsonEncode(body);
        print('JSON Body: $jsonBody');
        response = await http.post(uri, headers: headers, body: jsonBody);
      }

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Agar 415 xatolik bo'lsa, form data bilan qayta urinish
      if (response.statusCode == 415 && !useFormData) {
        print('Retrying with form data...');
        return await post(endpoint, body: body, includeAuth: includeAuth, useFormData: true);
      }

      // Token expired bo'lsa refresh qilish
      if (response.statusCode == 401 && includeAuth) {
        bool refreshed = await _refreshToken();
        if (refreshed) {
          return await post(endpoint, body: body, includeAuth: includeAuth, useFormData: useFormData);
        }
      }

      return response;
    } catch (e) {
      print('POST Error: $e');
      rethrow;
    }
  }

  // Qolgan metodlar bir xil...
  Future<http.Response> get(String endpoint, {bool includeAuth = true}) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      print('GET Request: $uri');
      print('Headers: $headers');

      final response = await http.get(uri, headers: headers);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 401 && includeAuth) {
        bool refreshed = await _refreshToken();
        if (refreshed) {
          final newHeaders = await _getHeaders(includeAuth: true);
          return await http.get(uri, headers: newHeaders);
        }
      }

      return response;
    } catch (e) {
      print('GET Error: $e');
      rethrow;
    }
  }

  Future<bool> _refreshToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null) return false;

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tokenRefresh}');
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode({'refresh': refreshToken});

      final response = await http.post(uri, headers: headers, body: body);

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

  // Patch va Delete metodlari ham shu tarzda...
  Future<http.Response> patch(String endpoint, {
    required Map<String, dynamic> body,
    bool includeAuth = true,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final jsonBody = jsonEncode(body);

      print('PATCH Request: $uri');
      print('Headers: $headers');
      print('Body: $jsonBody');

      final response = await http.patch(uri, headers: headers, body: jsonBody);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 401 && includeAuth) {
        bool refreshed = await _refreshToken();
        if (refreshed) {
          final newHeaders = await _getHeaders(includeAuth: true);
          return await http.patch(uri, headers: newHeaders, body: jsonBody);
        }
      }

      return response;
    } catch (e) {
      print('PATCH Error: $e');
      rethrow;
    }
  }

  Future<http.Response> delete(String endpoint, {bool includeAuth = true}) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      print('DELETE Request: $uri');
      print('Headers: $headers');

      final response = await http.delete(uri, headers: headers);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 401 && includeAuth) {
        bool refreshed = await _refreshToken();
        if (refreshed) {
          final newHeaders = await _getHeaders(includeAuth: true);
          return await http.delete(uri, headers: newHeaders);
        }
      }

      return response;
    } catch (e) {
      print('DELETE Error: $e');
      rethrow;
    }
  }
}
