class RainfallLog {
  final String id;
  final String sensorId;
  final double rainfall;
  final String unit;
  final String intensity;
  final DateTime recordedAt;
  final DateTime createdAt;

  RainfallLog({
    required this.id,
    required this.sensorId,
    required this.rainfall,
    required this.unit,
    required this.intensity,
    required this.recordedAt,
    required this.createdAt,
  });

  factory RainfallLog.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final sensorId = json['sensor_id']?.toString() ?? json['sensorId']?.toString() ?? '';
    
    double rainfall = 0.0;
    final rfRaw = json['rainfall'];
    if (rfRaw is num) {
      rainfall = rfRaw.toDouble();
    }

    final unit = json['unit']?.toString() ?? 'mm/hour';
    final intensity = json['intensity']?.toString() ?? 'LIGHT';

    final recordedAtRaw = json['recorded_at'] ?? json['recordedAt'];
    final recordedAt = recordedAtRaw != null
        ? DateTime.tryParse(recordedAtRaw.toString())?.toLocal() ?? DateTime.now()
        : DateTime.now();

    final createdAtRaw = json['created_at'] ?? json['createdAt'];
    final createdAt = createdAtRaw != null
        ? DateTime.tryParse(createdAtRaw.toString())?.toLocal() ?? DateTime.now()
        : DateTime.now();

    return RainfallLog(
      id: id,
      sensorId: sensorId,
      rainfall: rainfall,
      unit: unit,
      intensity: intensity,
      recordedAt: recordedAt,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sensorId': sensorId,
      'rainfall': rainfall,
      'unit': unit,
      'intensity': intensity,
      'recordedAt': recordedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
