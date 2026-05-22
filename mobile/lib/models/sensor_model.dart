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
  final String id;
  final String sensorId;
  final String name;
  final String type; // WATER_LEVEL, RAINFALL, FLOW_RATE
  final double latitude;
  final double longitude;
  final int? batteryLevel;
  final String connectivity; // ONLINE, OFFLINE, MAINTENANCE
  final DateTime? installedAt;
  final DateTime? lastActiveAt;
  final bool isActive;

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
    this.lastActiveAt,
    required this.isActive,
  });

  factory SensorModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final sensorId = json['sensor_id']?.toString() ?? json['sensorId']?.toString() ?? '';
    final name = json['name']?.toString() ?? '';
    final type = json['type']?.toString() ?? 'WATER_LEVEL';
    
    double lat = 0.0;
    if (json['latitude'] is num) {
      lat = (json['latitude'] as num).toDouble();
    }
    double lng = 0.0;
    if (json['longitude'] is num) {
      lng = (json['longitude'] as num).toDouble();
    }

    final batteryRaw = json['battery_level'] ?? json['batteryLevel'];
    final batteryLevel = batteryRaw is num ? batteryRaw.toInt() : null;

    final connectivity = json['connectivity']?.toString() ?? 'ONLINE';

    final installedAtRaw = json['installed_at'] ?? json['installedAt'];
    final installedAt = installedAtRaw != null
        ? DateTime.tryParse(installedAtRaw.toString())?.toLocal()
        : null;

    final lastActiveAtRaw = json['last_active_at'] ?? json['lastActiveAt'];
    final lastActiveAt = lastActiveAtRaw != null
        ? DateTime.tryParse(lastActiveAtRaw.toString())?.toLocal()
        : null;

    final isActive = json['is_active'] ?? json['isActive'] ?? true;

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
      lastActiveAt: lastActiveAt,
      isActive: isActive is bool ? isActive : (isActive.toString().toLowerCase() == 'true'),
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
      'last_active_at': lastActiveAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  Color get connectivityColor {
    switch (connectivity.toUpperCase()) {
      case 'ONLINE':
        return const Color(0xFF22C55E); // Green
      case 'OFFLINE':
        return const Color(0xFFEF4444); // Red
      case 'MAINTENANCE':
        return const Color(0xFFEAB308); // Yellow
      default:
        return const Color(0xFF94A3B8); // Slate
    }
  }
}


