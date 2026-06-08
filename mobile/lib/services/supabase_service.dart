import 'dart:async';
import 'package:flutter/foundation.dart';
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
  // StreamControllers to publish realtime events
  final _waterLevelController = StreamController<WaterLevelLog>.broadcast();
  final _alertController = StreamController<AlertModel>.broadcast();
  final _sensorController = StreamController<SensorModel>.broadcast();

  Stream<WaterLevelLog> get waterLevelStream => _waterLevelController.stream;
  Stream<AlertModel> get alertStream => _alertController.stream;
  Stream<SensorModel> get sensorStream => _sensorController.stream;

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
      _initialized = true;
      debugPrint('⚡ Supabase Initialized successfully!');
    } catch (e) {
      debugPrint('❌ Error initializing Supabase: $e');
    }
  }

  void subscribeToRealtime() {
    debugPrint('📡 [SupabaseService] Realtime PostgreSQL CDC is disabled. Standardized on NestJS SSE stream instead.');
  }

  void unsubscribe() {
    // No-op since we deactivated Supabase realtime streams
  }

  void dispose() {
    _waterLevelController.close();
    _alertController.close();
    _sensorController.close();
  }
}
