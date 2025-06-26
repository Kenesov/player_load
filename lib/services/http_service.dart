import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class HttpService {
  static final HttpService _instance = HttpService._internal();
  factory HttpService() => _instance;
  HttpService._internal();

  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    Map<String, String> headers = {
      'Accept': 'application/json',
    };

    if (includeAuth) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('access_token');
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<http.Response> get(String endpoint, {bool includeAuth = true}) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      print('GET Request: $uri');
      print('Headers: $headers');

      final response = await http.get(uri, headers: headers);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Token expired bo'lsa refresh qilish
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

  Future<http.Response> post(String endpoint, {
    required Map<String, dynamic> body,
    bool includeAuth = true,
    bool forceJson = false,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      print('POST Request: $uri');
      print('Headers: $headers');

      // Agar forceJson true bo'lsa yoki complex data bo'lsa, JSON ishlatish
      bool useJson = forceJson || _hasComplexData(body);

      if (useJson) {
        return await _postWithJson(uri, headers, body);
      } else {
        // Avval form-data bilan urinish
        final formData = <String, String>{};
        body.forEach((key, value) {
          if (value != null) {
            formData[key] = value.toString();
          }
        });

        print('Form Data: $formData');

        final response = await http.post(uri, headers: headers, body: formData);

        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');

        // Agar form-data ishlamasa, JSON bilan urinish
        if (response.statusCode == 415 || response.statusCode == 400) {
          print('Form-data failed, trying with JSON...');
          return await _postWithJson(uri, headers, body);
        }

        // Token expired bo'lsa refresh qilish
        if (response.statusCode == 401 && includeAuth) {
          bool refreshed = await _refreshToken();
          if (refreshed) {
            return await post(endpoint, body: body, includeAuth: includeAuth, forceJson: forceJson);
          }
        }

        return response;
      }
    } catch (e) {
      print('POST Error: $e');
      rethrow;
    }
  }

  bool _hasComplexData(Map<String, dynamic> body) {
    for (var value in body.values) {
      if (value is List || value is Map) {
        return true;
      }
    }
    return false;
  }

  Future<http.Response> _postWithJson(Uri uri, Map<String, String> headers, Map<String, dynamic> body) async {
    try {
      final client = http.Client();
      final request = http.Request('POST', uri);

      // Headers qo'shish
      request.headers.addAll(headers);
      request.headers['Content-Type'] = 'application/json';

      // Body qo'shish
      request.body = jsonEncode(body);

      print('JSON POST Request: $uri');
      print('JSON Headers: ${request.headers}');
      print('JSON Body: ${request.body}');

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      print('JSON Response Status: ${response.statusCode}');
      print('JSON Response Body: ${response.body}');

      client.close();
      return response;
    } catch (e) {
      print('JSON POST Error: $e');
      rethrow;
    }
  }

  Future<http.Response> patch(String endpoint, {
    required Map<String, dynamic> body,
    bool includeAuth = true,
    bool forceJson = false,
  }) async {
    try {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      bool useJson = forceJson || _hasComplexData(body);

      if (useJson) {
        return await _patchWithJson(uri, headers, body);
      } else {
        // Form data bilan urinish
        final formData = <String, String>{};
        body.forEach((key, value) {
          if (value != null) {
            formData[key] = value.toString();
          }
        });

        print('PATCH Request: $uri');
        print('Headers: $headers');
        print('Form Data: $formData');

        final response = await http.patch(uri, headers: headers, body: formData);

        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');

        // Token expired bo'lsa refresh qilish
        if (response.statusCode == 401 && includeAuth) {
          bool refreshed = await _refreshToken();
          if (refreshed) {
            return await patch(endpoint, body: body, includeAuth: includeAuth, forceJson: forceJson);
          }
        }

        return response;
      }
    } catch (e) {
      print('PATCH Error: $e');
      rethrow;
    }
  }

  Future<http.Response> _patchWithJson(Uri uri, Map<String, String> headers, Map<String, dynamic> body) async {
    try {
      final client = http.Client();
      final request = http.Request('PATCH', uri);

      request.headers.addAll(headers);
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);

      print('JSON PATCH Request: $uri');
      print('JSON Headers: ${request.headers}');
      print('JSON Body: ${request.body}');

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      print('JSON Response Status: ${response.statusCode}');
      print('JSON Response Body: ${response.body}');

      client.close();
      return response;
    } catch (e) {
      print('JSON PATCH Error: $e');
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

      // Token expired bo'lsa refresh qilish
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

  Future<bool> _refreshToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null) return false;

      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tokenRefresh}');

      // Form data bilan refresh token yuborish
      final formData = {'refresh': refreshToken};

      final response = await http.post(uri, body: formData);

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
}
