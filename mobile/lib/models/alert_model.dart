class AlertModel {
  final String id;
  final String title;
  final String message;
  final String severity; // INFO, WARNING, ALERT, DANGER
  final List<String> channels;
  final String? targetArea;
  final String? sentBy;
  final DateTime sentAt;
  final DateTime createdAt;

  AlertModel({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.channels,
    this.targetArea,
    this.sentBy,
    required this.sentAt,
    required this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final title = json['title']?.toString() ?? '';
    final message = json['message']?.toString() ?? '';
    final severity = json['severity']?.toString() ?? 'INFO';

    List<String> parsedChannels = [];
    final channelsRaw = json['channels'];
    if (channelsRaw is List) {
      parsedChannels = channelsRaw.map((e) => e.toString()).toList();
    } else if (channelsRaw is String) {
      parsedChannels = [channelsRaw];
    }

    final targetArea = json['target_area']?.toString() ?? json['targetArea']?.toString();
    final sentBy = json['sent_by']?.toString() ?? json['sentBy']?.toString();

    final sentAtRaw = json['sent_at'] ?? json['sentAt'];
    final sentAt = sentAtRaw != null
        ? DateTime.tryParse(sentAtRaw.toString())?.toLocal() ?? DateTime.now()
        : DateTime.now();

    final createdAtRaw = json['created_at'] ?? json['createdAt'];
    final createdAt = createdAtRaw != null
        ? DateTime.tryParse(createdAtRaw.toString())?.toLocal() ?? DateTime.now()
        : DateTime.now();

    return AlertModel(
      id: id,
      title: title,
      message: message,
      severity: severity,
      channels: parsedChannels,
      targetArea: targetArea,
      sentBy: sentBy,
      sentAt: sentAt,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'severity': severity,
      'channels': channels,
      'targetArea': targetArea,
      'sentBy': sentBy,
      'sentAt': sentAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
