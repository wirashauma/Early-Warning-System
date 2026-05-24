import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/api_service.dart';
import '../models/water_level_log.dart';
import '../models/rainfall_log.dart';
import '../models/flow_rate_log.dart';
import '../models/alert_model.dart';
import '../models/sensor_model.dart';
import '../services/supabase_service.dart';

class TelemetryProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SupabaseService _supabaseService = SupabaseService();

  bool _isLoading = false;
  String? _errorMessage;

  List<WaterLevelLog> _waterLevelHistory = [];
  List<RainfallLog> _rainfallHistory = [];
  List<FlowRateLog> _flowRateHistory = [];
  List<SensorModel> _sensors = [];
  List<AlertModel> _activeAlerts = [];

  AlertModel? _activeRealtimeAlert; // Populated when a "DANGER" alert is broadcasted realtime
  
  // Stream Subscriptions
  StreamSubscription<WaterLevelLog>? _waterLevelSub;
  StreamSubscription<AlertModel>? _alertSub;
  StreamSubscription<SensorModel>? _sensorSub;

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
  
  int get warningCount => _sensors.where((s) => 
    s.status?.toUpperCase() == 'WARNING' || 
    s.status?.toUpperCase() == 'ALERT' || 
    s.status?.toUpperCase() == 'WASPADA'
  ).length;

  int get dangerCount => _sensors.where((s) => 
    s.status?.toUpperCase() == 'DANGER' || 
    s.status?.toUpperCase() == 'BAHAYA'
  ).length;

  TelemetryProvider() {
    _initRealtimeSubscriptions();
  }

  void _initRealtimeSubscriptions() {
    // 1. Listen to Realtime Water Level Updates
    _waterLevelSub = _supabaseService.waterLevelStream.listen((log) {
      debugPrint('🌊 TelemetryProvider: Realtime Water Level Log Appended: ${log.waterLevel} cm');
      
      // Append to the list and notify listeners to rebuild fl_chart
      _waterLevelHistory.add(log);
      
      // Prevent unbounded growth in memory; keep the last 50 entries
      if (_waterLevelHistory.length > 50) {
        _waterLevelHistory.removeAt(0);
      }

      // Also update the sensor's telemetry values directly if it exists in our cache
      final sensorIdx = _sensors.indexWhere((s) => s.id == log.sensorId || s.sensorId == log.sensorId);
      if (sensorIdx != -1) {
        _sensors[sensorIdx] = _sensors[sensorIdx].copyWith(
          waterLevel: log.waterLevel.toDouble(),
          status: log.status,
          updatedAt: log.recordedAt,
        );
      }

      notifyListeners();
    });

    // 2. Listen to Realtime Danger Alerts
    _alertSub = _supabaseService.alertStream.listen((alert) {
      debugPrint('🔥 TelemetryProvider: Realtime Alert Broadcast: ${alert.title}');
      
      _activeAlerts.insert(0, alert);
      
      // Trigger Red Banner Overlay if severity is DANGER
      if (alert.severity.toUpperCase() == 'DANGER') {
        _activeRealtimeAlert = alert;
      }
      
      notifyListeners();
    });

    // 3. Listen to Realtime Sensor Status Changes
    _sensorSub = _supabaseService.sensorStream.listen((updatedSensor) {
      debugPrint('📡 TelemetryProvider: Realtime Sensor Status Updated: ${updatedSensor.sensorId} is ${updatedSensor.connectivity}');
      
      final index = _sensors.indexWhere((s) => s.id == updatedSensor.id || s.sensorId == updatedSensor.sensorId);
      if (index != -1) {
        _sensors[index] = updatedSensor.copyWith(
          waterLevel: _sensors[index].waterLevel,
          rainfall: _sensors[index].rainfall,
          flowRate: _sensors[index].flowRate,
          status: _sensors[index].status,
        );
      } else {
        _sensors.add(updatedSensor);
      }
      
      notifyListeners();
    });
  }

  // Clear or dismiss active danger alert
  void dismissDangerAlert() {
    _activeRealtimeAlert = null;
    notifyListeners();
  }

  // REST Data Loading
  Future<void> loadInitialData({String? sensorId}) async {
    _isLoading = true;
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
          (item) => item is Map<String, dynamic> && item['sensorId']?.toString() == s.sensorId,
          orElse: () => null,
        );
        final waterLevel = wl != null ? (wl['waterLevel'] as num?)?.toDouble() : null;
        final status = wl != null ? wl['status']?.toString() : null;

        // Match rainfall
        final rf = _rainfallCurrent.firstWhere(
          (item) => item is Map<String, dynamic> && item['sensorId']?.toString() == s.sensorId,
          orElse: () => null,
        );
        final rainfall = rf != null ? (rf['rainfall'] as num?)?.toDouble() : null;

        // Match flow rate
        final fr = _flowRateCurrent.firstWhere(
          (item) => item is Map<String, dynamic> && item['sensorId']?.toString() == s.sensorId,
          orElse: () => null,
        );
        final flowRate = fr != null ? (fr['flowRate'] as num?)?.toDouble() : null;

        _sensors[i] = s.copyWith(
          waterLevel: waterLevel,
          rainfall: rainfall,
          flowRate: flowRate,
          status: status,
        );
      }

      // 2. Fetch Histories with required date parameters and safe sensorId fallback
      final targetSensorId = sensorId ?? (_sensors.isNotEmpty ? _sensors.first.sensorId : null);
      if (targetSensorId != null) {
        final now = DateTime.now();
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        final startIso = sevenDaysAgo.toUtc().toIso8601String();
        final endIso = now.toUtc().toIso8601String();

        _waterLevelHistory = await _apiService.fetchWaterLevelHistory(
          sensorId: targetSensorId,
          startDate: startIso,
          endDate: endIso,
          limit: 20,
        );

        _rainfallHistory = await _apiService.fetchRainfallHistory(
          sensorId: targetSensorId,
          startDate: startIso,
          endDate: endIso,
          limit: 20,
        );

        _flowRateHistory = await _apiService.fetchFlowRateHistory(
          sensorId: targetSensorId,
          startDate: startIso,
          endDate: endIso,
          limit: 20,
        );
      } else {
        _waterLevelHistory = [];
        _rainfallHistory = [];
        _flowRateHistory = [];
      }

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
    final targetSensorId = sensorId ?? (_sensors.isNotEmpty ? _sensors.first.sensorId : null);
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
    _waterLevelSub?.cancel();
    _alertSub?.cancel();
    _sensorSub?.cancel();
    super.dispose();
  }
}
