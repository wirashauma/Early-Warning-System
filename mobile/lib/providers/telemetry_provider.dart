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
        // If we want to change any fields we can update the state locally or trigger refresh
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
        _sensors[index] = updatedSensor;
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

      // 2. Fetch Histories
      _waterLevelHistory = await _apiService.fetchWaterLevelHistory(
        sensorId: sensorId,
        limit: 20,
      );

      _rainfallHistory = await _apiService.fetchRainfallHistory(
        sensorId: sensorId,
        limit: 20,
      );

      _flowRateHistory = await _apiService.fetchFlowRateHistory(
        sensorId: sensorId,
        limit: 20,
      );

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
    try {
      _waterLevelHistory = await _apiService.fetchWaterLevelHistory(
        sensorId: sensorId,
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
