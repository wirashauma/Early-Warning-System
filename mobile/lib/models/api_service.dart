import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'water_level_log.dart';
import 'rainfall_log.dart';
import 'flow_rate_log.dart';
import 'alert_model.dart';
import 'sensor_model.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  String baseUrl =
      (dotenv.env['API_URL']?.trim()) ??
      (dotenv.env['API_BASE_URL']?.trim()) ??
      (dotenv.env['NEXT_PUBLIC_API_URL']?.trim()) ??
      'http://10.0.2.2:4101/api';

  /// Request timeout in seconds
  final int requestTimeoutSeconds =
      int.tryParse(dotenv.env['API_TIMEOUT'] ?? '') ?? 10;

  String? accessToken;
  String? refreshToken;

  Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  Uri _buildUri(String path, [Map<String, String>? query]) {
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse(
      '$baseUrl/$normalizedPath',
    ).replace(queryParameters: query);
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
    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(Duration(seconds: requestTimeoutSeconds));
      return _parseResponse(response);
    } on Exception catch (e) {
      if (e is http.ClientException ||
          e is TimeoutException ||
          e is SocketException) {
        throw ApiException(0, 'Network error: ${e.toString()}');
      }
      rethrow;
    }
  }

  Future<dynamic> post(String path, Object? body) async {
    final uri = _buildUri(path);
    try {
      final response = await http
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(Duration(seconds: requestTimeoutSeconds));
      return _parseResponse(response);
    } on Exception catch (e) {
      if (e is http.ClientException ||
          e is TimeoutException ||
          e is SocketException) {
        throw ApiException(0, 'Network error: ${e.toString()}');
      }
      rethrow;
    }
  }

  Future<dynamic> put(String path, Object? body) async {
    final uri = _buildUri(path);
    try {
      final response = await http
          .put(uri, headers: _headers, body: jsonEncode(body))
          .timeout(Duration(seconds: requestTimeoutSeconds));
      return _parseResponse(response);
    } on Exception catch (e) {
      if (e is http.ClientException ||
          e is TimeoutException ||
          e is SocketException) {
        throw ApiException(0, 'Network error: ${e.toString()}');
      }
      rethrow;
    }
  }

  Future<dynamic> delete(String path) async {
    final uri = _buildUri(path);
    try {
      final response = await http
          .delete(uri, headers: _headers)
          .timeout(Duration(seconds: requestTimeoutSeconds));
      return _parseResponse(response);
    } on Exception catch (e) {
      if (e is http.ClientException ||
          e is TimeoutException ||
          e is SocketException) {
        throw ApiException(0, 'Network error: ${e.toString()}');
      }
      rethrow;
    }
  }

  Future<dynamic> updateUser(String id, Map<String, dynamic> data) async {
    return await put('/users/$id', data);
  }

  Future<dynamic> deleteUser(String id) async {
    return await delete('/users/$id');
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
        })
        as Map<String, dynamic>;
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
    return await post('auth/google-login', {'idToken': idToken})
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> refreshSession(String refreshToken) async {
    return await post('auth/refresh', {'refreshToken': refreshToken})
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> me() async {
    return await get('auth/me') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(
    String name, {
    String? avatar,
  }) async {
    final body = <String, dynamic>{'name': name.trim()};
    if (avatar != null) {
      body['avatar'] = avatar;
    }
    return await put('auth/profile', body) as Map<String, dynamic>;
  }

  // ==========================================
  // TELEMETRY & ALERTS HISTORY METHODS
  // ==========================================

  Future<List<WaterLevelLog>> fetchWaterLevelHistory({
    String? sensorId,
    String? startDate,
    String? endDate,
    String? interval,
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (sensorId != null) queryParams['sensorId'] = sensorId;
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;
    if (interval != null) queryParams['interval'] = interval;

    final response = await get(
      'water-levels/history',
      queryParams: queryParams,
    );

    // In our NestJS architecture, success response is either { status: 'success', data: [...] }
    // or just direct [...] depending on how the data was nested, but `get()` automatically
    // returns response['data'] if the key exists (lines 45-47 in _parseResponse!).
    // Therefore, we can cast or map directly.
    final list = response as List<dynamic>? ?? [];
    return list
        .map((item) => WaterLevelLog.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<RainfallLog>> fetchRainfallHistory({
    String? sensorId,
    String? startDate,
    String? endDate,
    String? interval,
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (sensorId != null) queryParams['sensorId'] = sensorId;
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;
    if (interval != null) queryParams['interval'] = interval;

    final response = await get('rainfall/history', queryParams: queryParams);
    final list = response as List<dynamic>? ?? [];
    return list
        .map((item) => RainfallLog.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<FlowRateLog>> fetchFlowRateHistory({
    String? sensorId,
    String? startDate,
    String? endDate,
    String? interval,
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (sensorId != null) queryParams['sensorId'] = sensorId;
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;
    if (interval != null) queryParams['interval'] = interval;

    final response = await get('flow-rate/history', queryParams: queryParams);
    final list = response as List<dynamic>? ?? [];
    return list
        .map((item) => FlowRateLog.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<AlertModel>> fetchActiveAlerts() async {
    final response = await get('alerts/active');
    final list = response as List<dynamic>? ?? [];
    return list
        .map((item) => AlertModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<AlertModel>> fetchAlertHistory({
    int page = 1,
    int limit = 10,
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };
    final response = await get('alerts/history', queryParams: queryParams);

    // Paginated responses might have a meta or list inside data
    if (response is Map<String, dynamic> && response.containsKey('alerts')) {
      final list = response['alerts'] as List<dynamic>? ?? [];
      return list
          .map((item) => AlertModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    final list = response as List<dynamic>? ?? [];
    return list
        .map((item) => AlertModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Convenience wrapper to send broadcast alerts
  Future<dynamic> sendBroadcastAlert({
    required String title,
    required String message,
    required String severity,
    required List<String> channels,
    String? targetArea,
    bool? pushEnabled,
  }) async {
    final body = {
      'title': title,
      'message': message,
      'severity': severity,
      'channels': channels,
    };
    if (targetArea != null) body['targetArea'] = targetArea;
    if (pushEnabled != null) body['pushEnabled'] = pushEnabled;

    return await post('alerts/broadcast', body);
  }

  /// Subscribe device push token to backend (register FCM token)
  Future<dynamic> subscribePushToken({
    required String token,
    String? targetArea,
  }) async {
    final body = {'token': token};
    if (targetArea != null) body['targetArea'] = targetArea;
    return await post('alerts/subscribe', body);
  }

  Future<List<SensorModel>> fetchSensors({int page = 1, int limit = 20}) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };
    final response = await get('sensors', queryParams: queryParams);

    if (response is Map<String, dynamic> && response.containsKey('sensors')) {
      final list = response['sensors'] as List<dynamic>? ?? [];
      return list
          .map((item) => SensorModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    final list = response as List<dynamic>? ?? [];
    return list
        .map((item) => SensorModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Download a generated report file (PDF or Excel) from the backend.
  /// Returns the raw bytes of the file.
  Future<List<int>> downloadReport({
    required String type, // water_level | rainfall | combined
    required String startDate,
    required String endDate,
    required String format, // pdf | excel
  }) async {
    final queryParams = {
      'type': type,
      'startDate': startDate,
      'endDate': endDate,
      'format': format,
    };
    final uri = _buildUri('reports/generate', queryParams);

    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(Duration(seconds: requestTimeoutSeconds));

      if (response.statusCode >= 400) {
        _parseResponse(response); // will throw ApiException
        throw ApiException(response.statusCode, 'Failed to download report');
      }

      return response.bodyBytes;
    } on Exception catch (e) {
      if (e is http.ClientException ||
          e is TimeoutException ||
          e is SocketException) {
        throw ApiException(0, 'Network error: ${e.toString()}');
      }
      rethrow;
    }
  }
}
