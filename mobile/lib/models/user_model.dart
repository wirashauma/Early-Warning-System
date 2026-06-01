class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? address;
  final bool notificationFlood;
  final bool notificationStatus;
  final bool notificationEmail;
  final DateTime? notificationReadAt;
  final List<String> readNotificationIds;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role = 'user',
    this.address,
    this.notificationFlood = true,
    this.notificationStatus = true,
    this.notificationEmail = false,
    this.notificationReadAt,
    this.readNotificationIds = const [],
    required this.createdAt,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? role,
    bool? notificationFlood,
    bool? notificationStatus,
    bool? notificationEmail,
    DateTime? notificationReadAt,
    List<String>? readNotificationIds,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      address: address ?? this.address,
      notificationFlood: notificationFlood ?? this.notificationFlood,
      notificationStatus: notificationStatus ?? this.notificationStatus,
      notificationEmail: notificationEmail ?? this.notificationEmail,
      notificationReadAt: notificationReadAt ?? this.notificationReadAt,
      readNotificationIds: readNotificationIds ?? this.readNotificationIds,
      createdAt: createdAt,
    );
  }

  static DateTime _parseDateTime(dynamic raw) {
    if (raw == null) {
      return DateTime.now();
    }

    if (raw is DateTime) {
      return raw.toLocal();
    }

    final parsed = DateTime.tryParse(raw.toString());
    return parsed?.toLocal() ?? DateTime.now();
  }

  static DateTime? _parseNullableDateTime(dynamic raw) {
    if (raw == null) return null;

    if (raw is DateTime) {
      return raw.toLocal();
    }

    return DateTime.tryParse(raw.toString())?.toLocal();
  }

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      role: map['role'] ?? 'user',
      address: map['address'] ?? map['institution'],
      notificationFlood:
          map['notificationFlood'] ?? map['notification_flood'] ?? true,
      notificationStatus:
          map['notificationStatus'] ?? map['notification_status'] ?? true,
      notificationEmail:
          map['notificationEmail'] ?? map['notification_email'] ?? false,
      notificationReadAt: _parseNullableDateTime(
        map['notificationReadAt'] ?? map['notification_read_at'],
      ),
      readNotificationIds: map['readNotificationIds'] != null
          ? List<String>.from(map['readNotificationIds'])
          : [],
      createdAt: _parseDateTime(map['createdAt'] ?? map['created_at']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'address': address,
    'institution': address,
    'notificationFlood': notificationFlood,
    'notificationStatus': notificationStatus,
    'notificationEmail': notificationEmail,
    'notificationReadAt': notificationReadAt?.toIso8601String(),
    'readNotificationIds': readNotificationIds,
    'createdAt': createdAt.toIso8601String(),
  };
}
