import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'sensor_model.dart';
import 'alert_model.dart';

class AdminService extends ChangeNotifier {
  final ApiService _apiService;
  bool _isAdmin = false;

  AdminService(this._apiService);

  bool get isAdmin => _isAdmin;

  /// Check if current user is admin (Case-Insensitive Fix)
  Future<bool> checkAdminStatus(String userId) async {
    try {
      final response = await _apiService.get('/auth/me');
      final user =
          response; // ApiService langsung mengembalikan data atau jsonBody

      // Amankan pengecekan role agar mendeteksi 'admin', 'Admin', maupun 'ADMIN'
      _isAdmin =
          user is Map<String, dynamic> &&
          user['role'] != null &&
          user['role'].toString().toUpperCase() == 'ADMIN';

      notifyListeners();
      return _isAdmin;
    } catch (e) {
      _isAdmin = false;
      notifyListeners();
      return false;
    }
  }

  void setAdminStatus(bool status) {
    _isAdmin = status;
    notifyListeners();
  }

  /// Get all sensors
  Future<List<dynamic>> getSensors() async {
    try {
      final response = await _apiService.get('/sensors');
      return response is List<dynamic> ? response : (response['items'] ?? []);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Gagal mengambil data sensor: $e');
    }
  }

  /// Create sensor
  Future<dynamic> createSensor({
    required String sensorId,
    required String name,
    required String type,
    required double latitude,
    required double longitude,
    required int batteryLevel,
    required String connectivity,
  }) async {
    try {
      return await _apiService.post('/sensors', {
        'sensorId': sensorId,
        'name': name,
        'type': type,
        'latitude': latitude,
        'longitude': longitude,
        'batteryLevel': batteryLevel,
        'connectivity': connectivity,
      });
    } catch (e) {
      throw Exception('Gagal membuat sensor: $e');
    }
  }

  /// Update sensor
  Future<dynamic> updateSensor({
    required String id,
    required String name,
    required double latitude,
    required double longitude,
    required int batteryLevel,
    required String connectivity,
    String? type,
    String? riverName,
    int? zeroCalibrationCm,
  }) async {
    try {
      final body = {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'batteryLevel': batteryLevel,
        'connectivity': connectivity,
      };
      if (type != null) body['type'] = type;
      if (riverName != null) body['riverName'] = riverName;
      if (zeroCalibrationCm != null) {
        body['zeroCalibrationCm'] = zeroCalibrationCm;
      }

      return await _apiService.put('/sensors/$id', body);
    } catch (e) {
      throw Exception('Gagal mengupdate sensor: $e');
    }
  }

  /// Delete sensor
  Future<void> deleteSensor(String id) async {
    try {
      await _apiService.delete('/sensors/$id');
    } catch (e) {
      throw Exception('Gagal menghapus sensor: $e');
    }
  }

  /// Get all users
  Future<List<dynamic>> getUsers() async {
    try {
      final response = await _apiService.get('/users');
      return response is List<dynamic> ? response : [];
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Gagal mengambil data pengguna: $e');
    }
  }

  /// Create user
  Future<dynamic> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? institution,
  }) async {
    try {
      return await _apiService.post('/users', {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'phone': phone,
        'institution': institution,
      });
    } catch (e) {
      throw Exception('Gagal membuat pengguna: $e');
    }
  }

  /// Update user
  Future<dynamic> updateUser({
    required String id,
    required String name,
    required String email,
    required String role,
    String? phone,
    String? institution,
    String? password,
  }) async {
    try {
      final body = {
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'institution': institution,
      };
      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }
      return await _apiService.put('/users/$id', body);
    } catch (e) {
      throw Exception('Gagal mengupdate pengguna: $e');
    }
  }

  /// Delete user
  Future<void> deleteUser(String id) async {
    try {
      await _apiService.delete('/users/$id');
    } catch (e) {
      throw Exception('Gagal menghapus pengguna: $e');
    }
  }

  /// Get current thresholds
  Future<Map<String, dynamic>> getThresholds() async {
    try {
      final response = await _apiService.get('/thresholds');
      return response is Map<String, dynamic> ? response : {};
    } catch (e) {
      throw Exception('Gagal mengambil ambang batas: $e');
    }
  }

  /// Update thresholds
  Future<dynamic> updateThresholds({
    required int normalMaxCm,
    required int warningMinCm,
    required int warningMaxCm,
    required int dangerMinCm,
    required double rainLightMax,
    required double rainModerateMax,
    required double rainHeavyMin,
  }) async {
    try {
      return await _apiService.put('/thresholds', {
        'waterLevel': {
          'normal': {'min': 0, 'max': normalMaxCm},
          'warning': {'min': warningMinCm, 'max': warningMaxCm},
          'danger': {'min': dangerMinCm, 'max': null},
        },
        'rainfall': {
          'light': {'min': 0, 'max': rainLightMax},
          'moderate': {'min': rainLightMax + 0.1, 'max': rainModerateMax},
          'heavy': {'min': rainHeavyMin, 'max': null},
        },
      });
    } catch (e) {
      throw Exception('Gagal mengupdate ambang batas: $e');
    }
  }

  /// Broadcast alert
  Future<dynamic> sendBroadcastAlert({
    required String title,
    required String message,
    required String severity,
    required List<String> channels,
    String? targetArea,
    bool? pushEnabled,
  }) async {
    try {
      final body = {
        'title': title,
        'message': message,
        'severity': severity,
        'channels': channels,
      };
      if (targetArea != null) body['targetArea'] = targetArea;
      if (pushEnabled != null) body['pushEnabled'] = pushEnabled;

      return await _apiService.post('/alerts/broadcast', body);
    } catch (e) {
      throw Exception('Gagal mengirim broadcast: $e');
    }
  }

  /// Get alert history
  Future<List<AlertModel>> getAlertHistory({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await _apiService.get(
        '/alerts/history',
        queryParams: {'page': page.toString(), 'limit': limit.toString()},
      );

      List<dynamic> items = [];
      if (response is Map<String, dynamic> && response.containsKey('items')) {
        items = response['items'] as List<dynamic>? ?? [];
      } else if (response is List<dynamic>) {
        items = response;
      }

      return items
          .map((i) => AlertModel.fromJson(i as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Gagal mengambil riwayat alert: $e');
    }
  }

  /// Get water levels current
  Future<List<dynamic>> getWaterLevelsCurrent() async {
    try {
      final response = await _apiService.get('/water-levels/current');
      return response is List<dynamic> ? response : [];
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Gagal mengambil level air: $e');
    }
  }

  /// Get rainfall current
  Future<List<dynamic>> getRainfallCurrent() async {
    try {
      final response = await _apiService.get('/rainfall/current');
      return response is List<dynamic> ? response : [];
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Gagal mengambil data hujan: $e');
    }
  }

  /// Get dashboard stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final sensors = await getSensors();
      final waterLevels = await getWaterLevelsCurrent();
      final rainfall = await getRainfallCurrent();
      final alerts = await getAlertHistory(limit: 10);
      final online = sensors.where((s) {
        if (s is! Map<String, dynamic>) return false;

        return SensorModel.isTimestampOnline(
          s['last_seen_at'] ??
              s['lastSeenAt'] ??
              s['last_active_at'] ??
              s['lastActiveAt'] ??
              s['updated_at'] ??
              s['updatedAt'] ??
              s['recorded_at'] ??
              s['recordedAt'],
        );
      }).length;
      final offline = sensors.length - online;

      final avgRainfall = rainfall.isEmpty
          ? 0.0
          : rainfall.fold<double>(
                  0,
                  (sum, r) =>
                      sum +
                      (r is Map<String, dynamic> ? (r['rainfall'] ?? 0) : 0),
                ) /
                rainfall.length;

      final warningCount = waterLevels.where((w) {
        final status = (w is Map<String, dynamic> ? (w['status'] ?? '') : '')
            .toString()
            .toUpperCase();
        return status == 'WARNING' || status == 'ALERT';
      }).length;

      final dangerCount = waterLevels.where((w) {
        final status = (w is Map<String, dynamic> ? (w['status'] ?? '') : '')
            .toString()
            .toUpperCase();
        return status == 'DANGER';
      }).length;

      final maxWaterLevelCm = waterLevels.fold<double>(0, (max, item) {
        final level = item is Map<String, dynamic> ? item['waterLevel'] : null;
        if (level is num && level.toDouble() > max) {
          return level.toDouble();
        }
        return max;
      });

      final globalStatus = dangerCount > 0
          ? 'Bahaya'
          : warningCount > 0
          ? 'Waspada'
          : 'Aman';

      return {
        'totalSensors': sensors.length,
        'onlineSensors': online,
        'offlineSensors': offline,
        'avgRainfall': (avgRainfall * 10).toInt() / 10,
        'warningCount': warningCount,
        'dangerCount': dangerCount,
        'maxWaterLevelCm': maxWaterLevelCm,
        'globalStatus': globalStatus,
        'sensors': sensors,
        'waterLevels': waterLevels,
        'recentAlerts': alerts,
      };
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Gagal mengambil statistik dashboard: $e');
    }
  }
}
