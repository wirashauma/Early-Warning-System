class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'user' or 'admin'
  final String address;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.role = 'user',
    this.address = '',
    required this.createdAt,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role,
      address: address ?? this.address,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
    'address': address,
    'createdAt': createdAt.toIso8601String(),
  };
}
