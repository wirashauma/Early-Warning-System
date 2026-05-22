class FlowRateLog {
  final String id;
  final String sensorId;
  final double flowRate;
  final String unit;
  final DateTime recordedAt;
  final DateTime createdAt;

  FlowRateLog({
    required this.id,
    required this.sensorId,
    required this.flowRate,
    required this.unit,
    required this.recordedAt,
    required this.createdAt,
  });

  factory FlowRateLog.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final sensorId = json['sensor_id']?.toString() ?? json['sensorId']?.toString() ?? '';
    
    double flowRate = 0.0;
    final frRaw = json['flow_rate'] ?? json['flowRate'];
    if (frRaw is num) {
      flowRate = frRaw.toDouble();
    }

    final unit = json['unit']?.toString() ?? 'l/min';

    final recordedAtRaw = json['recorded_at'] ?? json['recordedAt'];
    final recordedAt = recordedAtRaw != null
        ? DateTime.tryParse(recordedAtRaw.toString())?.toLocal() ?? DateTime.now()
        : DateTime.now();

    final createdAtRaw = json['created_at'] ?? json['createdAt'];
    final createdAt = createdAtRaw != null
        ? DateTime.tryParse(createdAtRaw.toString())?.toLocal() ?? DateTime.now()
        : DateTime.now();

    return FlowRateLog(
      id: id,
      sensorId: sensorId,
      flowRate: flowRate,
      unit: unit,
      recordedAt: recordedAt,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sensorId': sensorId,
      'flowRate': flowRate,
      'unit': unit,
      'recordedAt': recordedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
