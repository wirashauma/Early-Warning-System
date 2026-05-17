import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3001/api',
  );

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

  Future<dynamic> _get(String path, {Map<String, String>? query}) async {
    final uri = _buildUri(path, query);
    final response = await http.get(uri, headers: _headers);
    return _parseResponse(response);
  }

  Future<dynamic> _post(String path, Object? body) async {
    final uri = _buildUri(path);
    final response = await http.post(uri, headers: _headers, body: jsonEncode(body));
    return _parseResponse(response);
  }

  Future<dynamic> _put(String path, Object? body) async {
    final uri = _buildUri(path);
    final response = await http.put(uri, headers: _headers, body: jsonEncode(body));
    return _parseResponse(response);
  }

  Future<dynamic> _delete(String path) async {
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
    return await _post('auth/login', {
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
    return await _post('auth/register', body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> refreshSession(String refreshToken) async {
    return await _post('auth/refresh', {
      'refreshToken': refreshToken,
    }) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> me() async {
    return await _get('auth/me') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(String name, {String? avatar}) async {
    final body = <String, dynamic>{
      'name': name.trim(),
    };
    if (avatar != null) {
      body['avatar'] = avatar;
    }
    return await _put('auth/profile', body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> broadcastAlert(
    String title,
    String message,
    String severity,
    List<String> channels, {
    String? targetArea,
  }) async {
    final body = {
      'title': title,
      'message': message,
      'severity': severity,
      'channels': channels,
    };
    if (targetArea != null) {
      body['targetArea'] = targetArea;
    }
    return await _post('alerts/broadcast', body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchActiveAlerts() async {
    return await _get('alerts/active') as List<dynamic>;
  }

  Future<List<dynamic>> fetchAlertHistory({int page = 1, int limit = 20}) async {
    return await _get('alerts/history', query: {
      'page': page.toString(),
      'limit': limit.toString(),
    }) as List<dynamic>;
  }

  Future<Map<String, dynamic>> fetchAlertById(String id) async {
    return await _get('alerts/$id') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> subscribeAlertToken(String token, {String? targetArea}) async {
    final body = {'token': token};
    if (targetArea != null) {
      body['targetArea'] = targetArea;
    }
    return await _post('alerts/subscribe', body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchEmergencyContacts() async {
    return await _get('emergency-contacts') as List<dynamic>;
  }

  Future<Map<String, dynamic>> fetchRainfallCurrent() async {
    return await _get('rainfall/current') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchWaterLevelsCurrent() async {
    return await _get('water-levels/current') as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchWaterLevelsHistory({String? sensorId, String? startDate, String? endDate, String interval = 'hourly', int page = 1, int limit = 20}) async {
    final query = <String, String>{
      if (sensorId != null) 'sensorId': sensorId,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      'interval': interval,
      'page': page.toString(),
      'limit': limit.toString(),
    };
    return await _get('water-levels/history', query: query) as List<dynamic>;
  }

  Future<Map<String, dynamic>> fetchWaterLevelLatestBySensor(String sensorId) async {
    return await _get('water-levels/$sensorId/latest') as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchSensorLocations() async {
    return await _get('locations/sensors') as List<dynamic>;
  }

  Future<Map<String, dynamic>> fetchThresholds() async {
    return await _get('thresholds') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateThresholds(Map<String, dynamic> payload) async {
    return await _put('thresholds', payload) as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchSensors({int page = 1, int limit = 20}) async {
    return await _get('sensors', query: {
      'page': page.toString(),
      'limit': limit.toString(),
    }) as List<dynamic>;
  }

  Future<Map<String, dynamic>> createSensor(Map<String, dynamic> payload) async {
    return await _post('sensors', payload) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSensor(String id, Map<String, dynamic> payload) async {
    return await _put('sensors/$id', payload) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteSensor(String id) async {
    return await _delete('sensors/$id') as Map<String, dynamic>;
  }

  Future<List<dynamic>> fetchUsers() async {
    return await _get('users') as List<dynamic>;
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> payload) async {
    return await _post('users', payload) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> payload) async {
    return await _put('users/$id', payload) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteUser(String id) async {
    return await _delete('users/$id') as Map<String, dynamic>;
  }
}
