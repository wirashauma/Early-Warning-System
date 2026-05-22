class WaterLevelLog {
  final String id;
  final String sensorId;
  final double waterLevel;
  final String unit;
  final String status;
  final DateTime recordedAt;
  final DateTime createdAt;

  WaterLevelLog({
    required this.id,
    required this.sensorId,
    required this.waterLevel,
    required this.unit,
    required this.status,
    required this.recordedAt,
    required this.createdAt,
  });

  factory WaterLevelLog.fromJson(Map<String, dynamic> json) {
    // Handle both snake_case (Supabase realtime payloads) and camelCase (NestJS REST API responses)
    final id = json['id']?.toString() ?? '';
    final sensorId = json['sensor_id']?.toString() ?? json['sensorId']?.toString() ?? '';
    
    double waterLevel = 0.0;
    final wlRaw = json['water_level'] ?? json['waterLevel'];
    if (wlRaw is num) {
      waterLevel = wlRaw.toDouble();
    }

    final unit = json['unit']?.toString() ?? 'meter';
    final status = json['status']?.toString() ?? 'NORMAL';

    final recordedAtRaw = json['recorded_at'] ?? json['recordedAt'];
    final recordedAt = recordedAtRaw != null
        ? DateTime.tryParse(recordedAtRaw.toString())?.toLocal() ?? DateTime.now()
        : DateTime.now();

    final createdAtRaw = json['created_at'] ?? json['createdAt'];
    final createdAt = createdAtRaw != null
        ? DateTime.tryParse(createdAtRaw.toString())?.toLocal() ?? DateTime.now()
        : DateTime.now();

    return WaterLevelLog(
      id: id,
      sensorId: sensorId,
      waterLevel: waterLevel,
      unit: unit,
      status: status,
      recordedAt: recordedAt,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sensorId': sensorId,
      'waterLevel': waterLevel,
      'unit': unit,
      'status': status,
      'recordedAt': recordedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
