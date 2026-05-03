import 'user_model.dart';

/// Simulasi auth service (tanpa backend nyata)
/// Ganti dengan API call ke backend Anda
class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // Dummy database pengguna terdaftar
  final List<Map<String, String>> _registeredUsers = [
    {
      'id': 'user_001',
      'name': 'Admin EWS',
      'email': 'admin@ewsfloodguard.id',
      'phone': '081234567890',
      'password': 'admin123',
      'role': 'admin',
      'address': 'Padang, Sumatera Barat',
    },
    {
      'id': 'user_002',
      'name': 'Wira Pratama',
      'email': 'wira@gmail.com',
      'phone': '082345678901',
      'password': 'wira123',
      'role': 'user',
      'address': 'Padang, Sumatera Barat',
    },
  ];

  /// Login dengan email & password
  Future<AuthResult> login(String email, String password) async {
    // Simulasi network delay
    await Future.delayed(const Duration(milliseconds: 1200));

    if (email.isEmpty || password.isEmpty) {
      return AuthResult.failure('Email dan password tidak boleh kosong.');
    }

    final user = _registeredUsers.where(
      (u) => u['email'] == email.trim().toLowerCase() && u['password'] == password,
    ).firstOrNull;

    if (user == null) {
      return AuthResult.failure('Email atau password salah. Silakan coba lagi.');
    }

    _currentUser = UserModel(
      id: user['id']!,
      name: user['name']!,
      email: user['email']!,
      phone: user['phone']!,
      role: user['role']!,
      address: user['address']!,
      createdAt: DateTime(2026, 1, 1),
    );

    return AuthResult.success(_currentUser!);
  }

  /// Register akun baru
  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String address = '',
  }) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      return AuthResult.failure('Semua field wajib diisi.');
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return AuthResult.failure('Format email tidak valid.');
    }

    if (phone.length < 10) {
      return AuthResult.failure('Nomor telepon minimal 10 digit.');
    }

    if (password.length < 6) {
      return AuthResult.failure('Password minimal 6 karakter.');
    }

    final exists = _registeredUsers.any((u) => u['email'] == email.trim().toLowerCase());
    if (exists) {
      return AuthResult.failure('Email sudah terdaftar. Silakan gunakan email lain.');
    }

    final newUser = {
      'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      'password': password,
      'role': 'user',
      'address': address.trim(),
    };

    _registeredUsers.add(newUser);

    _currentUser = UserModel(
      id: newUser['id']!,
      name: newUser['name']!,
      email: newUser['email']!,
      phone: newUser['phone']!,
      role: 'user',
      address: newUser['address']!,
      createdAt: DateTime.now(),
    );

    return AuthResult.success(_currentUser!);
  }

  /// Reset password (simulasi)
  Future<AuthResult> forgotPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    if (email.isEmpty) {
      return AuthResult.failure('Email tidak boleh kosong.');
    }

    final exists = _registeredUsers.any((u) => u['email'] == email.trim().toLowerCase());
    if (!exists) {
      return AuthResult.failure('Email tidak ditemukan dalam sistem kami.');
    }

    return AuthResult.success(null, message: 'Link reset password telah dikirim ke $email');
  }

  /// Update profil
  Future<AuthResult> updateProfile({
    required String name,
    required String phone,
    required String address,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (_currentUser == null) {
      return AuthResult.failure('Anda belum login.');
    }

    _currentUser = _currentUser!.copyWith(
      name: name,
      phone: phone,
      address: address,
    );

    // Update di list juga
    final idx = _registeredUsers.indexWhere((u) => u['id'] == _currentUser!.id);
    if (idx != -1) {
      _registeredUsers[idx]['name'] = name;
      _registeredUsers[idx]['phone'] = phone;
      _registeredUsers[idx]['address'] = address;
    }

    return AuthResult.success(_currentUser!);
  }

  /// Logout
  void logout() {
    _currentUser = null;
  }
}

class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final String? message;
  final UserModel? user;

  AuthResult._({required this.isSuccess, this.errorMessage, this.message, this.user});

  factory AuthResult.success(UserModel? user, {String? message}) =>
      AuthResult._(isSuccess: true, user: user, message: message);

  factory AuthResult.failure(String error) =>
      AuthResult._(isSuccess: false, errorMessage: error);
}
