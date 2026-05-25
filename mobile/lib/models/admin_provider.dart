import 'package:flutter/foundation.dart';
import 'admin_service.dart'; // FIX: Mengarah langsung ke file di folder yang sama
import 'api_service.dart';
import 'alert_model.dart';

class AdminProvider extends ChangeNotifier {
  late AdminService adminService;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAdmin = false;
  Map<String, dynamic> _dashboardStats = {};
  List<dynamic> _sensors = [];
  List<dynamic> _users = [];
  List<AlertModel> _alertHistory = [];

  AdminProvider({ApiService? apiService}) {
    adminService = AdminService(apiService ?? ApiService());
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _isAdmin;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  List<dynamic> get sensors => _sensors;
  List<dynamic> get users => _users;
  List<AlertModel> get alertHistory => _alertHistory;

  int get onlineSensorsCount => (_dashboardStats['onlineSensors'] as int?) ?? 0;
  int get offlineSensorsCount =>
      (_dashboardStats['offlineSensors'] as int?) ?? 0;
  int get warningCount => (_dashboardStats['warningCount'] as int?) ?? 0;
  int get dangerCount => (_dashboardStats['dangerCount'] as int?) ?? 0;
  double get avgRainfall =>
      (_dashboardStats['avgRainfall'] as num?)?.toDouble() ?? 0.0;
  double get maxWaterLevelCm =>
      (_dashboardStats['maxWaterLevelCm'] as num?)?.toDouble() ?? 0.0;
  String get globalStatus =>
      (_dashboardStats['globalStatus'] as String?) ?? 'Aman';

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> checkAdminRole(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _isAdmin = await adminService.checkAdminStatus(userId);
    } catch (e) {
      _errorMessage = 'Error checking admin status: $e';
      _isAdmin = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDashboardStats() async {
    debugPrint('[AdminProvider] loadDashboardStats() start');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final stats = await adminService.getDashboardStats();
      debugPrint('[AdminProvider] dashboard stats loaded: $stats');
      _dashboardStats = stats;
      if (_dashboardStats.containsKey('sensors')) {
        _sensors = _dashboardStats['sensors'] as List<dynamic>;
      } else {
        _sensors = [];
      }
      debugPrint(
        '[AdminProvider] sensors=${_sensors.length}, online=$onlineSensorsCount, offline=$offlineSensorsCount, warning=$warningCount, danger=$dangerCount, global=$globalStatus',
      );
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _dashboardStats = {};
      _sensors = [];
      debugPrint('[AdminProvider] loadDashboardStats ApiException: $e');
      rethrow;
    } catch (e) {
      _errorMessage = e.toString();
      _dashboardStats = {};
      _sensors = [];
      debugPrint('[AdminProvider] loadDashboardStats error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<dynamic>> loadAlertHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final list = await adminService.getAlertHistory();
      _alertHistory = list;
      return _alertHistory;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> broadcastAlert({
    required String title,
    required String message,
    required String severity,
    required List<String> channels,
    String? targetArea,
    bool? pushEnabled,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await adminService.sendBroadcastAlert(
        title: title,
        message: message,
        severity: severity,
        channels: channels,
        targetArea: targetArea,
        pushEnabled: pushEnabled,
      );

      // refresh history after successful send
      await loadAlertHistory();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================
  // MANAJEMEN SENSOR (CRUD)
  // ==========================================
  Future<List<dynamic>> loadSensors() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await adminService.getSensors();
      _sensors = response;
      return _sensors;
    } catch (e) {
      _errorMessage = 'Gagal memuat data sensor: $e';
      _sensors = [];
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSensor({
    required String sensorId,
    required String name,
    required String type,
    required double latitude,
    required double longitude,
    required int batteryLevel,
    required String connectivity,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await adminService.createSensor(
        sensorId: sensorId,
        name: name,
        type: type,
        latitude: latitude,
        longitude: longitude,
        batteryLevel: batteryLevel,
        connectivity: connectivity,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSensor({
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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await adminService.updateSensor(
        id: id,
        name: name,
        latitude: latitude,
        longitude: longitude,
        batteryLevel: batteryLevel,
        connectivity: connectivity,
        type: type,
        riverName: riverName,
        zeroCalibrationCm: zeroCalibrationCm,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteSensor(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await adminService.deleteSensor(id);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================
  // MANAJEMEN AMBANG BATAS (THRESHOLDS)
  // ==========================================
  Future<Map<String, dynamic>> loadThresholds() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await adminService.getThresholds();
    } catch (e) {
      _errorMessage = 'Gagal memuat ambang batas: $e';
      return {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateThresholds({
    required int normalMaxCm,
    required int warningMinCm,
    required int warningMaxCm,
    required int dangerMinCm,
    required double rainLightMax,
    required double rainModerateMax,
    required double rainHeavyMin,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await adminService.updateThresholds(
        normalMaxCm: normalMaxCm,
        warningMinCm: warningMinCm,
        warningMaxCm: warningMaxCm,
        dangerMinCm: dangerMinCm,
        rainLightMax: rainLightMax,
        rainModerateMax: rainModerateMax,
        rainHeavyMin: rainHeavyMin,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==========================================
  // MANAJEMEN PENGGUNA (USERS)
  // ==========================================
  Future<List<dynamic>> loadUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _users = await adminService.getUsers();
      return _users;
    } catch (e) {
      _errorMessage = 'Gagal memuat data pengguna: $e';
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? institution,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await adminService.createUser(
        name: name,
        email: email,
        password: password,
        role: role,
        phone: phone,
        institution: institution,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUser({
    required String id,
    required String name,
    required String email,
    required String role,
    String? phone,
    String? institution,
    String? password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await adminService.updateUser(
        id: id,
        name: name,
        email: email,
        role: role,
        phone: phone,
        institution: institution,
        password: password,
      );
      await loadUsers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteUser(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await adminService.deleteUser(id);
      await loadUsers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
