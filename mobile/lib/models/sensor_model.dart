import 'package:flutter/material.dart';

class SensorData {
  final String name;
  final String location;
  final double waterLevel;
  final double rainfall;
  final String status;
  final DateTime lastUpdate;

  SensorData({
    required this.name,
    required this.location,
    required this.waterLevel,
    required this.rainfall,
    required this.status,
    required this.lastUpdate,
  });

  Color get statusColor {
    switch (status) {
      case 'Normal':
        return const Color(0xFF22C55E);
      case 'Waspada':
        return const Color(0xFF3B82F6);
      case 'Siaga':
        return const Color(0xFF0EA5E9);
      case 'Bahaya':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF22C55E);
    }
  }
}

class SensorModel {
  static const Duration onlineThreshold = Duration(minutes: 3);

  final String id;
  final String sensorId;
  final String name;
  final String type; // WATER_LEVEL, RAINFALL, FLOW_RATE
  final double latitude;
  final double longitude;
  final int? batteryLevel;
  final String connectivity; // ONLINE, OFFLINE, MAINTENANCE
  final DateTime? installedAt;
  final DateTime? lastSeenAt;
  final DateTime? lastActiveAt;
  final DateTime? updatedAt;
  final bool isActive;
  final double? waterLevel;
  final double? rainfall;
  final double? flowRate;
  final String? status;

  SensorModel({
    required this.id,
    required this.sensorId,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.batteryLevel,
    required this.connectivity,
    this.installedAt,
    this.lastSeenAt,
    this.lastActiveAt,
    this.updatedAt,
    required this.isActive,
    this.waterLevel,
    this.rainfall,
    this.flowRate,
    this.status,
  });

  SensorModel copyWith({
    double? waterLevel,
    double? rainfall,
    double? flowRate,
    String? status,
    String? connectivity,
    int? batteryLevel,
    DateTime? lastSeenAt,
    DateTime? lastActiveAt,
    DateTime? updatedAt,
  }) {
    return SensorModel(
      id: id,
      sensorId: sensorId,
      name: name,
      type: type,
      latitude: latitude,
      longitude: longitude,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      connectivity: connectivity ?? this.connectivity,
      installedAt: installedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive,
      waterLevel: waterLevel ?? this.waterLevel,
      rainfall: rainfall ?? this.rainfall,
      flowRate: flowRate ?? this.flowRate,
      status: status ?? this.status,
    );
  }

  static DateTime? parseTimestamp(dynamic raw) {
    if (raw == null) return null;

    if (raw is DateTime) {
      return raw.toLocal();
    }

    if (raw is num) {
      final value = raw.toInt();
      final milliseconds = value.abs() < 1000000000000 ? value * 1000 : value;
      return DateTime.fromMillisecondsSinceEpoch(
        milliseconds,
        isUtc: true,
      ).toLocal();
    }

    final parsed = DateTime.tryParse(raw.toString());
    return parsed?.toLocal();
  }

  static bool isTimestampOnline(
    dynamic raw, {
    DateTime? now,
    Duration threshold = onlineThreshold,
  }) {
    final timestamp = parseTimestamp(raw);
    if (timestamp == null) return false;

    final reference = now ?? DateTime.now();
    return reference.difference(timestamp).inMilliseconds <=
        threshold.inMilliseconds;
  }

  static String _normalizeConnectivity(dynamic raw) {
    final value = raw == null ? '' : raw.toString().trim().toUpperCase();
    if (value == 'ONLINE' || value == 'OFFLINE' || value == 'MAINTENANCE') {
      return value;
    }
    return 'UNKNOWN';
  }

  static bool _parseBool(dynamic raw, {bool fallback = false}) {
    if (raw == null) return fallback;
    if (raw is bool) return raw;
    return raw.toString().toLowerCase() == 'true';
  }

  DateTime? get effectiveLastSeenAt => lastSeenAt ?? lastActiveAt ?? updatedAt;

  bool get isOnline => isTimestampOnline(effectiveLastSeenAt);

  String get displayConnectivity => isOnline ? 'ONLINE' : 'OFFLINE';

  factory SensorModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final sensorId =
        json['sensor_id']?.toString() ?? json['sensorId']?.toString() ?? '';
    final name = json['name']?.toString() ?? '';
    final type = json['type']?.toString() ?? 'WATER_LEVEL';

    final latitudeRaw = json['latitude'];
    final longitudeRaw = json['longitude'];
    final lat = latitudeRaw is num
        ? latitudeRaw.toDouble()
        : double.tryParse(latitudeRaw?.toString() ?? '') ?? 0.0;
    final lng = longitudeRaw is num
        ? longitudeRaw.toDouble()
        : double.tryParse(longitudeRaw?.toString() ?? '') ?? 0.0;

    final batteryRaw = json['battery_level'] ?? json['batteryLevel'];
    final batteryLevel = batteryRaw is num ? batteryRaw.toInt() : null;

    final connectivity = _normalizeConnectivity(
      json['connectivity'] ??
          json['connectivityStatus'] ??
          json['connectivity_status'] ??
          json['status'],
    );

    final installedAtRaw = json['installed_at'] ?? json['installedAt'];
    final installedAt = parseTimestamp(installedAtRaw);

    final lastSeenAtRaw = json['last_seen_at'] ?? json['lastSeenAt'];
    final lastSeenAt = parseTimestamp(lastSeenAtRaw);

    final lastActiveAtRaw = json['last_active_at'] ?? json['lastActiveAt'];
    final lastActiveAt = parseTimestamp(lastActiveAtRaw);

    final updatedAtRaw = json['updated_at'] ?? json['updatedAt'];
    final updatedAt = parseTimestamp(updatedAtRaw);

    final isActive = _parseBool(
      json['is_active'] ?? json['isActive'],
      fallback: true,
    );

    final waterLevelRaw = json['waterLevel'] ?? json['water_level'];
    final waterLevel = waterLevelRaw is num ? waterLevelRaw.toDouble() : null;

    final rainfallRaw = json['rainfall'] ?? json['rainfall_mm'] ?? json['rainfallMm'];
    final rainfall = rainfallRaw is num ? rainfallRaw.toDouble() : null;

    final flowRateRaw = json['flowRate'] ?? json['flow_rate'] ?? json['flowRateLpm'];
    final flowRate = flowRateRaw is num ? flowRateRaw.toDouble() : null;

    final status = json['status']?.toString();

    return SensorModel(
      id: id,
      sensorId: sensorId,
      name: name,
      type: type,
      latitude: lat,
      longitude: lng,
      batteryLevel: batteryLevel,
      connectivity: connectivity,
      installedAt: installedAt,
      lastSeenAt: lastSeenAt,
      lastActiveAt: lastActiveAt,
      updatedAt: updatedAt,
      isActive: isActive,
      waterLevel: waterLevel,
      rainfall: rainfall,
      flowRate: flowRate,
      status: status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sensor_id': sensorId,
      'name': name,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'battery_level': batteryLevel,
      'connectivity': connectivity,
      'installed_at': installedAt?.toIso8601String(),
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'last_active_at': lastActiveAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive,
      'water_level': waterLevel,
      'rainfall': rainfall,
      'flow_rate': flowRate,
      'status': status,
    };
  }

  Color get connectivityColor {
    switch (connectivity.toUpperCase()) {
      case 'MAINTENANCE':
        return const Color(0xFFEAB308); // Yellow
      case 'ONLINE':
      case 'OFFLINE':
        return isOnline ? const Color(0xFF22C55E) : const Color(0xFFEF4444);
      default:
        return isOnline ? const Color(0xFF22C55E) : const Color(0xFF94A3B8);
    }
  }
}
