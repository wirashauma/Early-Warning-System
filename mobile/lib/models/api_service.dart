import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'water_level_log.dart';
import 'rainfall_log.dart';
import 'flow_rate_log.dart';
import 'alert_model.dart';
import 'sensor_model.dart';
import 'emergency_contact_model.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  ApiService._internal();
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  static const String _accessTokenKey = 'ews_access_token';
  static const String _refreshTokenKey = 'ews_refresh_token';

  static String _resolveBaseUrl() {
    final value = dotenv.env['API_URL']?.trim();

    if (value == null || value.isEmpty) {
      throw StateError(
        '[EWS] Missing required API_URL in mobile/.env. Configure the backend API base URL before starting the app.',
      );
    }

    return value;
  }

  final String baseUrl = _resolveBaseUrl();

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

  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
    bool persist = true,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;

    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
  }

  Future<void> loadPersistedTokens() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString(_accessTokenKey);
    refreshToken = prefs.getString(_refreshTokenKey);
  }

  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  // Authentication
  Future<Map<String, dynamic>> login(String email, String password) async {
    return await post('auth/login', {
          'email': email.trim().toLowerCase(),
          'password': password,
        })
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? institution,
  }) async {
    final body = {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
      'phone': phone.trim(),
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
    String? phone,
    String? institution,
    bool? notificationFlood,
    bool? notificationStatus,
    bool? notificationEmail,
  }) async {
    final body = <String, dynamic>{'name': name.trim()};
    if (avatar != null) {
      body['avatar'] = avatar;
    }
    if (phone != null) {
      body['phone'] = phone.trim();
    }
    if (institution != null) {
      body['institution'] = institution.trim();
    }
    if (notificationFlood != null) {
      body['notificationFlood'] = notificationFlood;
    }
    if (notificationStatus != null) {
      body['notificationStatus'] = notificationStatus;
    }
    if (notificationEmail != null) {
      body['notificationEmail'] = notificationEmail;
    }
    return await put('auth/profile', body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> markNotificationsReadAll() async {
    return await put('notifications/read-all', {}) as Map<String, dynamic>;
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

    final List<dynamic> list;
    if (response is Map<String, dynamic> && response.containsKey('items')) {
      list = response['items'] as List<dynamic>? ?? [];
    } else if (response is List<dynamic>) {
      list = response;
    } else {
      list = [];
    }
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
    final List<dynamic> list;
    if (response is Map<String, dynamic> && response.containsKey('items')) {
      list = response['items'] as List<dynamic>? ?? [];
    } else if (response is List<dynamic>) {
      list = response;
    } else {
      list = [];
    }
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
    final List<dynamic> list;
    if (response is Map<String, dynamic> && response.containsKey('items')) {
      list = response['items'] as List<dynamic>? ?? [];
    } else if (response is List<dynamic>) {
      list = response;
    } else {
      list = [];
    }
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

    final List<dynamic> list;
    if (response is Map<String, dynamic>) {
      if (response.containsKey('alerts')) {
        list = response['alerts'] as List<dynamic>? ?? [];
      } else if (response.containsKey('items')) {
        list = response['items'] as List<dynamic>? ?? [];
      } else {
        list = [];
      }
    } else if (response is List<dynamic>) {
      list = response;
    } else {
      list = [];
    }
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

    final List<dynamic> list;
    if (response is Map<String, dynamic>) {
      if (response.containsKey('sensors')) {
        list = response['sensors'] as List<dynamic>? ?? [];
      } else if (response.containsKey('items')) {
        list = response['items'] as List<dynamic>? ?? [];
      } else {
        list = [];
      }
    } else if (response is List<dynamic>) {
      list = response;
    } else {
      list = [];
    }
    return list
        .map((item) => SensorModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Fetch active emergency contacts from the public backend endpoint.
  /// Returns the database list or falls back to a hardcoded list when offline.
  Future<List<EmergencyContactModel>> fetchEmergencyContacts() async {
    try {
      final response = await get('emergency-contacts');
      final List<dynamic> list;
      if (response is List<dynamic>) {
        list = response;
      } else if (response is Map<String, dynamic> &&
          response.containsKey('items')) {
        list = response['items'] as List<dynamic>? ?? [];
      } else {
        list = [];
      }
      final contacts = list
          .map(
            (item) =>
                EmergencyContactModel.fromJson(item as Map<String, dynamic>),
          )
          .where((c) => c.isActive)
          .toList();
      return contacts.isEmpty
          ? EmergencyContactModel.fallbackList
          : contacts;
    } catch (_) {
      return EmergencyContactModel.fallbackList;
    }
  }

  /// Download generated report file bytes (PDF or Excel) via authenticated API call.
  Future<List<int>> downloadReportBytes({
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
        try {
          _parseResponse(
            response,
          ); // will throw ApiException with backend message
        } catch (e) {
          if (e is ApiException) {
            rethrow;
          }
        }

        throw ApiException(
          response.statusCode,
          'Gagal mengunduh laporan (HTTP ${response.statusCode})',
        );
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
