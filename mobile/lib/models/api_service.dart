import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  String baseUrl = dotenv.env['API_URL']?.trim() ??
      dotenv.env['API_BASE_URL']?.trim() ??
      'http://10.0.2.2:3001/api';

  String? accessToken;
  String? refreshToken;

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  Uri _buildUri(String path, [Map<String, String>? query]) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$baseUrl/$normalizedPath').replace(queryParameters: query);
  }

  dynamic _parseResponse(http.Response response) {
    final body = response.body.isEmpty ? '{}' : response.body;
    final jsonBody = jsonDecode(body);
    if (response.statusCode >= 400) {
      final message = jsonBody is Map<String, dynamic>
          ? (jsonBody['message'] ?? jsonBody['error'] ?? 'Request failed')
          : 'Request failed';
      throw ApiException(response.statusCode, message.toString());
    }
    if (jsonBody is Map<String, dynamic> && jsonBody.containsKey('data')) {
      return jsonBody['data'];
    }
    return jsonBody;
  }

  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    final uri = _buildUri(path, queryParams);
    final response = await http.get(uri, headers: _headers);
    return _parseResponse(response);
  }

  Future<dynamic> post(String path, Object? body) async {
    final uri = _buildUri(path);
    final response = await http.post(uri, headers: _headers, body: jsonEncode(body));
    return _parseResponse(response);
  }

  Future<dynamic> put(String path, Object? body) async {
    final uri = _buildUri(path);
    final response = await http.put(uri, headers: _headers, body: jsonEncode(body));
    return _parseResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final uri = _buildUri(path);
    final response = await http.delete(uri, headers: _headers);
    return _parseResponse(response);
  }

  void setTokens({required String accessToken, required String refreshToken}) {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  void clearTokens() {
    accessToken = null;
    refreshToken = null;
  }

  // Authentication
  Future<Map<String, dynamic>> login(String email, String password) async {
    return await post('auth/login', {
      'email': email.trim().toLowerCase(),
      'password': password,
    }) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password, {
    String? institution,
  }) async {
    final body = {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    };
    if (institution != null && institution.isNotEmpty) {
      body['institution'] = institution.trim();
    }
    return await post('auth/register', body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> googleLogin(String idToken) async {
    return await post('auth/google-login', {'idToken': idToken}) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> refreshSession(String refreshToken) async {
    return await post('auth/refresh', {'refreshToken': refreshToken}) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> me() async {
    return await get('auth/me') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(String name, {String? avatar}) async {
    final body = <String, dynamic>{'name': name.trim()};
    if (avatar != null) {
      body['avatar'] = avatar;
    }
    return await put('auth/profile', body) as Map<String, dynamic>;
  }
}