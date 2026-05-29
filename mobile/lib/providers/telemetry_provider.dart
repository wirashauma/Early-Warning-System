import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/api_service.dart';
import '../models/water_level_log.dart';
import '../models/rainfall_log.dart';
import '../models/flow_rate_log.dart';
import '../models/alert_model.dart';
import '../models/sensor_model.dart';
import '../services/sse_client.dart';

class TelemetryProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _errorMessage;

  List<WaterLevelLog> _waterLevelHistory = [];
  List<RainfallLog> _rainfallHistory = [];
  List<FlowRateLog> _flowRateHistory = [];
  List<SensorModel> _sensors = [];
  List<AlertModel> _activeAlerts = [];

  AlertModel?
  _activeRealtimeAlert; // Populated when a "DANGER" alert is broadcasted realtime

  // SSE Client & Subscription
  SseClient? _sseClient;
  StreamSubscription<SseEvent>? _sseSub;

  Timer? _pollingTimer;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<WaterLevelLog> get waterLevelHistory => _waterLevelHistory;
  List<RainfallLog> get rainfallHistory => _rainfallHistory;
  List<FlowRateLog> get flowRateHistory => _flowRateHistory;
  List<SensorModel> get sensors => _sensors;
  List<AlertModel> get activeAlerts => _activeAlerts;
  AlertModel? get activeRealtimeAlert => _activeRealtimeAlert;

  List<dynamic> _waterLevelsCurrent = [];
  List<dynamic> _rainfallCurrent = [];
  List<dynamic> _flowRateCurrent = [];

  List<dynamic> get waterLevelsCurrent => _waterLevelsCurrent;
  List<dynamic> get rainfallCurrent => _rainfallCurrent;
  List<dynamic> get flowRateCurrent => _flowRateCurrent;

  int get onlineSensorsCount => _sensors.where((s) => s.isOnline).length;
  int get offlineSensorsCount => _sensors.length - onlineSensorsCount;

  int get warningCount => _sensors
      .where(
        (s) =>
            s.status?.toUpperCase() == 'WARNING' ||
            s.status?.toUpperCase() == 'ALERT' ||
            s.status?.toUpperCase() == 'WASPADA',
      )
      .length;

  int get dangerCount => _sensors
      .where(
        (s) =>
            s.status?.toUpperCase() == 'DANGER' ||
            s.status?.toUpperCase() == 'BAHAYA',
      )
      .length;

  TelemetryProvider() {
    _startBackgroundPolling();
  }

  void _startBackgroundPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      loadInitialData(silent: true);
    });
  }

  // Clear or dismiss active danger alert
  void dismissDangerAlert() {
    _activeRealtimeAlert = null;
    notifyListeners();
  }

  // REST Data Loading
  Future<void> loadInitialData({String? sensorId, bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch Sensors
      _sensors = await _apiService.fetchSensors(limit: 50);

      // Fetch current telemetry data from endpoints
      try {
        final wlCurrent = await _apiService.get('water-levels/current');
        _waterLevelsCurrent = wlCurrent is List<dynamic> ? wlCurrent : [];
      } catch (e) {
        debugPrint('Failed to fetch current water levels: $e');
        _waterLevelsCurrent = [];
      }

      try {
        final rfCurrent = await _apiService.get('rainfall/current');
        _rainfallCurrent = rfCurrent is List<dynamic> ? rfCurrent : [];
      } catch (e) {
        debugPrint('Failed to fetch current rainfall: $e');
        _rainfallCurrent = [];
      }

      try {
        final frCurrent = await _apiService.get('flow-rate/current');
        _flowRateCurrent = frCurrent is List<dynamic> ? frCurrent : [];
      } catch (e) {
        debugPrint('Failed to fetch current flow rates: $e');
        _flowRateCurrent = [];
      }

      // Merge current telemetry details into the _sensors model list
      for (int i = 0; i < _sensors.length; i++) {
        final s = _sensors[i];

        // Match water level
        final wl = _waterLevelsCurrent.firstWhere(
          (item) =>
              item is Map<String, dynamic> &&
              item['sensorId']?.toString() == s.sensorId,
          orElse: () => null,
        );
        final waterLevel = wl != null
            ? (wl['waterLevel'] as num?)?.toDouble()
            : null;
        final status = wl != null ? wl['status']?.toString() : null;

        // Match rainfall
        final rf = _rainfallCurrent.firstWhere(
          (item) =>
              item is Map<String, dynamic> &&
              item['sensorId']?.toString() == s.sensorId,
          orElse: () => null,
        );
        final rainfall = rf != null
            ? (rf['rainfall'] as num?)?.toDouble()
            : null;

        // Match flow rate
        final fr = _flowRateCurrent.firstWhere(
          (item) =>
              item is Map<String, dynamic> &&
              item['sensorId']?.toString() == s.sensorId,
          orElse: () => null,
        );
        final flowRate = fr != null
            ? (fr['flowRate'] as num?)?.toDouble()
            : null;

        _sensors[i] = s.copyWith(
          waterLevel: waterLevel,
          rainfall: rainfall,
          flowRate: flowRate,
          status: status,
        );
      }

      // 2. Keep history lists empty here; the dashboard loads per-sensor history
      // only when a matching sensor is selected. This avoids querying the wrong
      // endpoint for mixed sensor inventories (e.g. flow sensor passed to
      // water-level history) and prevents false 404s on app startup.
      _waterLevelHistory = [];
      _rainfallHistory = [];
      _flowRateHistory = [];

      // 3. Fetch Active Alerts
      _activeAlerts = await _apiService.fetchActiveAlerts();

      debugPrint('✅ TelemetryProvider: Loaded initial data successfully.');
    } catch (e) {
      _errorMessage = 'Gagal memuat data telemetri: $e';
      debugPrint('❌ TelemetryProvider Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh Single Metri (e.g. manually triggered)
  Future<void> refreshWaterLevels({String? sensorId}) async {
    final targetSensorId =
        sensorId ?? (_sensors.isNotEmpty ? _sensors.first.sensorId : null);
    if (targetSensorId == null) return;
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      _waterLevelHistory = await _apiService.fetchWaterLevelHistory(
        sensorId: targetSensorId,
        startDate: sevenDaysAgo.toUtc().toIso8601String(),
        endDate: now.toUtc().toIso8601String(),
        limit: 20,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing water levels: $e');
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _sseSub?.cancel();
    _sseClient?.close();
    super.dispose();
  }
}
