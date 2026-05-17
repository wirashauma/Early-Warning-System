import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';
import 'user_model.dart';

class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  AuthResult({required this.isSuccess, this.errorMessage});
}

class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final ApiService _apiService = ApiService();

  UserModel _mapBackendUserToModel(Map<String, dynamic> userData) {
    return UserModel(
      id: userData['id'] ?? '',
      name: userData['name'] ?? 'User',
      email: userData['email'] ?? '',
      phone: userData['phone'],
      role: (userData['role'] ?? 'user').toString(),
      address: userData['address'],
      createdAt: userData['createdAt'] != null
          ? DateTime.parse(userData['createdAt'])
          : DateTime.now(),
    );
  }

  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      
      final accessToken = response['accessToken'] as String?;
      final refreshToken = response['refreshToken'] as String?;
      final userData = response['user'] as Map<String, dynamic>?;

      if (accessToken == null || userData == null) {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'Respons server tidak valid',
        );
      }

      _apiService.setTokens(
        accessToken: accessToken,
        refreshToken: refreshToken ?? '',
      );

      _currentUser = _mapBackendUserToModel(userData);
      return AuthResult(isSuccess: true);
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? address,
  }) async {
    try {
      final response = await _apiService.register(
        name,
        email,
        password,
        institution: address,
      );

      final accessToken = response['accessToken'] as String?;
      final refreshToken = response['refreshToken'] as String?;
      final userData = response['user'] as Map<String, dynamic>?;

      if (accessToken == null || userData == null) {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'Respons server tidak valid',
        );
      }

      _apiService.setTokens(
        accessToken: accessToken,
        refreshToken: refreshToken ?? '',
      );

      _currentUser = _mapBackendUserToModel(userData);
      return AuthResult(isSuccess: true);
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<AuthResult> loginWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'Google login dibatalkan',
        );
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'Gagal mendapatkan ID Token dari Google',
        );
      }

      // Send idToken ke backend /auth/google-login
      final response = await _apiService.googleLogin(idToken);

      final accessToken = response['accessToken'] as String?;
      final refreshToken = response['refreshToken'] as String?;
      final userData = response['user'] as Map<String, dynamic>?;

      if (accessToken == null || userData == null) {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'Respons server tidak valid',
        );
      }

      _apiService.setTokens(
        accessToken: accessToken,
        refreshToken: refreshToken ?? '',
      );

      _currentUser = _mapBackendUserToModel(userData);
      return AuthResult(isSuccess: true);
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        errorMessage: 'Google login gagal: ${e.toString()}',
      );
    }
  }

  Future<AuthResult> updateProfile({
    required String name,
    required String phone,
    required String address,
  }) async {
    try {
      if (_currentUser == null) {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'User tidak login',
        );
      }

      await _apiService.updateProfile(name);

      _currentUser = _currentUser!.copyWith(
        name: name,
        phone: phone,
        address: address,
      );
      return AuthResult(isSuccess: true);
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<AuthResult> forgotPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return AuthResult(isSuccess: true);
    } catch (e) {
      return AuthResult(
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  void logout() {
    _googleSignIn.signOut();
    _firebaseAuth.signOut();
    _apiService.clearTokens();
    _currentUser = null;
  }
}