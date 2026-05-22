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

