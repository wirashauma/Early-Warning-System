import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
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
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final ApiService _apiService = ApiService();

  Future<bool> restoreSession() async {
    try {
      await _apiService.loadPersistedTokens();

      final accessToken = _apiService.accessToken;
      final refreshToken = _apiService.refreshToken;

      if (accessToken == null || accessToken.isEmpty) {
        _currentUser = null;
        return false;
      }

      try {
        final userData = await _apiService.me();
        _currentUser = _mapBackendUserToModel(userData);
        return true;
      } catch (e) {
        if (refreshToken == null || refreshToken.isEmpty) {
          await _apiService.clearTokens();
          _currentUser = null;
          return false;
        }

        final refreshed = await _apiService.refreshSession(refreshToken);
        final newAccessToken = refreshed['accessToken'] as String?;
        final newRefreshToken =
            refreshed['refreshToken'] as String? ?? refreshToken;

        if (newAccessToken == null || newAccessToken.isEmpty) {
          await _apiService.clearTokens();
          _currentUser = null;
          return false;
        }

        await _apiService.setTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        final userData = await _apiService.me();
        _currentUser = _mapBackendUserToModel(userData);
        return true;
      }
    } catch (e) {
      debugPrint('[AuthService] restoreSession failed: $e');
      await _apiService.clearTokens();
      _currentUser = null;
      return false;
    }
  }

  UserModel _mapBackendUserToModel(Map<String, dynamic> userData) {
    return UserModel.fromMap(userData['id']?.toString() ?? '', {
      ...userData,
      'address': userData['address'] ?? userData['institution'],
    });
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

      await _apiService.setTokens(
        accessToken: accessToken,
        refreshToken: refreshToken ?? '',
      );

      _currentUser = _mapBackendUserToModel(userData);
      return AuthResult(isSuccess: true);
    } catch (e) {
      return AuthResult(isSuccess: false, errorMessage: e.toString());
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
        name: name,
        email: email,
        password: password,
        phone: phone,
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

      await _apiService.setTokens(
        accessToken: accessToken,
        refreshToken: refreshToken ?? '',
      );

      _currentUser = _mapBackendUserToModel(userData);
      return AuthResult(isSuccess: true);
    } catch (e) {
      return AuthResult(isSuccess: false, errorMessage: e.toString());
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

      await _apiService.setTokens(
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
    bool? notificationFlood,
    bool? notificationStatus,
    bool? notificationEmail,
  }) async {
    try {
      if (_currentUser == null) {
        return AuthResult(isSuccess: false, errorMessage: 'User tidak login');
      }

      await _apiService.updateProfile(
        name,
        phone: phone,
        institution: address,
        notificationFlood: notificationFlood,
        notificationStatus: notificationStatus,
        notificationEmail: notificationEmail,
      );

      _currentUser = _currentUser!.copyWith(
        name: name,
        phone: phone,
        address: address,
        notificationFlood: notificationFlood,
        notificationStatus: notificationStatus,
        notificationEmail: notificationEmail,
      );
      return AuthResult(isSuccess: true);
    } catch (e) {
      return AuthResult(isSuccess: false, errorMessage: e.toString());
    }
  }

  Future<AuthResult> forgotPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return AuthResult(isSuccess: true);
    } catch (e) {
      return AuthResult(isSuccess: false, errorMessage: e.toString());
    }
  }

  Future<void> logout() async {
    try {
      _apiService.post('auth/logout', {}).catchError((e) {
        debugPrint('[AuthService] Backend logout failed: $e');
        return null;
      });
    } catch (e) {
      debugPrint('[AuthService] Backend logout error: $e');
    }
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
    await _apiService.clearTokens();
    _currentUser = null;
  }

  Future<AuthResult> markNotificationsReadAll() async {
    try {
      if (_currentUser == null) {
        return AuthResult(isSuccess: false, errorMessage: 'User tidak login');
      }

      await _apiService.markNotificationsReadAll();
      _currentUser = _currentUser!.copyWith(notificationReadAt: DateTime.now());
      return AuthResult(isSuccess: true);
    } catch (e) {
      return AuthResult(isSuccess: false, errorMessage: e.toString());
    }
  }
}
