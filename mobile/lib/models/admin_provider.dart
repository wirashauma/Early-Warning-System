import 'package:flutter/foundation.dart';
import 'admin_service.dart'; // FIX: Mengarah langsung ke file di folder yang sama
import 'api_service.dart';

class AdminProvider extends ChangeNotifier {
  late AdminService adminService;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAdmin = false;
  Map<String, dynamic> _dashboardStats = {};
  List<dynamic> _sensors = [];
  List<dynamic> _users = [];

  AdminProvider({ApiService? apiService}) {
    adminService = AdminService(apiService ?? ApiService());
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _isAdmin;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  List<dynamic> get sensors => _sensors;
  List<dynamic> get users => _users;

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
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _dashboardStats = await adminService.getDashboardStats();
      if (_dashboardStats.containsKey('sensors')) {
        _sensors = _dashboardStats['sensors'] as List<dynamic>;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<dynamic>> loadAlertHistory() async {
    try {
      return await adminService.getAlertHistory();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  Future<bool> broadcastAlert({
    required String title,
    required String message,
    required String severity,
    required List<String> channels,
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