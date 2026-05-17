import 'api_service.dart';
import 'user_model.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  final ApiService _api = ApiService.instance;
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  Future<AuthResult> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      return AuthResult.failure('Email dan password tidak boleh kosong.');
    }

    try {
      final data = await _api.login(email, password);
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;
      final userData = data['user'] as Map<String, dynamic>;

      _api.setTokens(accessToken: accessToken, refreshToken: refreshToken);
      _currentUser = UserModel.fromMap(userData);

      return AuthResult.success(_currentUser!);
    } on ApiException catch (error) {
      return AuthResult.failure(error.message);
    } catch (_) {
      return AuthResult.failure('Login gagal. Silakan coba lagi.');
    }
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String? institution,
  }) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      return AuthResult.failure('Nama, email, dan password wajib diisi.');
    }

    try {
      final data = await _api.register(name, email, password, institution: institution);
      _currentUser = UserModel.fromMap(data as Map<String, dynamic>);
      return AuthResult.success(_currentUser!, message: 'Registrasi berhasil. Silakan login.');
    } on ApiException catch (error) {
      return AuthResult.failure(error.message);
    } catch (_) {
      return AuthResult.failure('Registrasi gagal. Silakan coba lagi.');
    }
  }

  Future<String?> forgotPassword(String email) async {
    if (email.isEmpty) {
      return 'Email tidak boleh kosong.';
    }
    return 'Fitur reset password belum tersedia pada backend. Silakan hubungi admin atau gunakan fitur web.';
  }

  Future<AuthResult> updateProfile({
    required String name,
    String? avatar,
  }) async {
    if (_currentUser == null) {
      return AuthResult.failure('Anda belum login.');
    }

    try {
      final data = await _api.updateProfile(name, avatar: avatar);
      _currentUser = UserModel.fromMap(data as Map<String, dynamic>);
      return AuthResult.success(_currentUser!, message: 'Profil berhasil diperbarui.');
    } on ApiException catch (error) {
      return AuthResult.failure(error.message);
    } catch (_) {
      return AuthResult.failure('Update profil gagal. Silakan coba lagi.');
    }
  }

  void logout() {
    _api.clearTokens();
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
