import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/water_level_log.dart';
import '../models/alert_model.dart';
import '../models/sensor_model.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _initialized = false;
  SupabaseClient? _client;

  // StreamControllers to publish realtime events
  final _waterLevelController = StreamController<WaterLevelLog>.broadcast();
  final _alertController = StreamController<AlertModel>.broadcast();
  final _sensorController = StreamController<SensorModel>.broadcast();

  Stream<WaterLevelLog> get waterLevelStream => _waterLevelController.stream;
  Stream<AlertModel> get alertStream => _alertController.stream;
  Stream<SensorModel> get sensorStream => _sensorController.stream;

  RealtimeChannel? _waterLevelChannel;
  RealtimeChannel? _alertChannel;
  RealtimeChannel? _sensorChannel;

  Future<void> initialize() async {
    if (_initialized) return;

    final url =
        dotenv.env['SUPABASE_URL']?.trim() ??
        dotenv.env['NEXT_PUBLIC_SUPABASE_URL']?.trim();
    final anonKey =
        dotenv.env['SUPABASE_ANON_KEY']?.trim() ??
        dotenv.env['NEXT_PUBLIC_SUPABASE_ANON_KEY']?.trim();

    if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
      throw StateError(
        '[EWS] Missing Supabase env values. Set SUPABASE_URL and SUPABASE_ANON_KEY in mobile/.env before initializing realtime features.',
      );
    }

    try {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _client = Supabase.instance.client;
      _initialized = true;
      print('⚡ Supabase Initialized successfully!');
    } catch (e) {
      print('❌ Error initializing Supabase: $e');
    }
  }

  void subscribeToRealtime() {
    if (!_initialized || _client == null) {
      print('⚠️ Cannot subscribe to realtime: Supabase not initialized.');
      return;
    }

    // Ensure we clear previous subscriptions if any
    unsubscribe();

    // 1. Subscribe to 'water_level_logs' (Event: INSERT)
    _waterLevelChannel = _client!
        .channel('public-water-levels-realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'water_level_logs',
          callback: (payload) {
            print(
              '🔥 Supabase: Water Level Log INSERT received: ${payload.newRecord}',
            );
            try {
              final log = WaterLevelLog.fromJson(payload.newRecord);
              _waterLevelController.add(log);
            } catch (e) {
              print('❌ Error parsing realtime water level log: $e');
            }
          },
        )
        .subscribe();

    // 2. Subscribe to 'alerts' (Event: INSERT)
    _alertChannel = _client!
        .channel('public-alerts-realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'alerts',
          callback: (payload) {
            print('🔥 Supabase: Alert INSERT received: ${payload.newRecord}');
            try {
              final alert = AlertModel.fromJson(payload.newRecord);
              _alertController.add(alert);
            } catch (e) {
              print('❌ Error parsing realtime alert log: $e');
            }
          },
        )
        .subscribe();

    // 3. Subscribe to 'sensors' (Event: UPDATE)
    _sensorChannel = _client!
        .channel('public-sensors-realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'sensors',
          callback: (payload) {
            print('🔥 Supabase: Sensor UPDATE received: ${payload.newRecord}');
            try {
              final sensor = SensorModel.fromJson(payload.newRecord);
              _sensorController.add(sensor);
            } catch (e) {
              print('❌ Error parsing realtime sensor update: $e');
            }
          },
        )
        .subscribe();

    print('📡 Subscribed to Supabase PostgreSQL Realtime channels!');
  }

  void unsubscribe() {
    if (_waterLevelChannel != null) {
      _client?.removeChannel(_waterLevelChannel!);
      _waterLevelChannel = null;
    }
    if (_alertChannel != null) {
      _client?.removeChannel(_alertChannel!);
      _alertChannel = null;
    }
    if (_sensorChannel != null) {
      _client?.removeChannel(_sensorChannel!);
      _sensorChannel = null;
    }
  }

  void dispose() {
    unsubscribe();
    _waterLevelController.close();
    _alertController.close();
    _sensorController.close();
  }
}
