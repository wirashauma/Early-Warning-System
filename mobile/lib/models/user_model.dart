class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? address;
  final String? avatar;
  final String? institution;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'user',
    this.phone,
    this.address,
    this.avatar,
    this.institution,
    this.createdAt,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? role,
    String? avatar,
    String? institution,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      institution: institution ?? this.institution,
      createdAt: createdAt,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      role: map['role'] as String? ?? 'user',
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      avatar: map['avatar'] as String?,
      institution: map['institution'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (avatar != null) 'avatar': avatar,
        if (institution != null) 'institution': institution,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };
}
