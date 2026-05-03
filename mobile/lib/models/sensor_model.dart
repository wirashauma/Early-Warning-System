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
        return const Color(0xFFF59E0B);
      case 'Siaga':
        return const Color(0xFFF97316);
      case 'Bahaya':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF22C55E);
    }
  }
}

final List<SensorData> dummySensors = [
  SensorData(
    name: 'Sensor Hulu',
    location: 'Batang Arau',
    waterLevel: 126,
    rainfall: 7,
    status: 'Normal',
    lastUpdate: DateTime(2026, 3, 16, 16, 2),
  ),
  SensorData(
    name: 'Sensor Tengah',
    location: 'Batang Arau',
    waterLevel: 155,
    rainfall: 12,
    status: 'Waspada',
    lastUpdate: DateTime(2026, 3, 16, 16, 2),
  ),
  SensorData(
    name: 'Sensor Hilir',
    location: 'Batang Arau',
    waterLevel: 165,
    rainfall: 15,
    status: 'Waspada',
    lastUpdate: DateTime(2026, 3, 16, 16, 2),
  ),
];
