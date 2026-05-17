import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService.instance;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _authService.isLoggedIn;
  UserModel? get currentUser => _authService.currentUser;
  String get userRole => _authService.currentUser?.role ?? 'user';

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    clearError();

    try {
      final result = await _authService.login(email, password);

      if (!result.isSuccess) {
        _errorMessage = result.errorMessage;
      }

      return result.isSuccess;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? address,
  }) async {
    _setLoading(true);
    clearError();

    try {
      final result = await _authService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        address: address,
      );

      if (!result.isSuccess) {
        _errorMessage = result.errorMessage;
      }

      return result.isSuccess;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> forgotPassword(String email) async {
    _setLoading(true);
    clearError();

    try {
      final result = await _authService.forgotPassword(email);

      if (result.isSuccess) {
        return "Instruksi reset password telah dikirim.";
      } else {
        _errorMessage = result.errorMessage;
        return null;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String phone,
    required String address,
  }) async {
    _setLoading(true);
    clearError();

    try {
      final result = await _authService.updateProfile(
        name: name,
        phone: phone,
        address: address,
      );

      if (!result.isSuccess) {
        _errorMessage = result.errorMessage;
      }

      return result.isSuccess;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    clearError();

    try {
      final result = await _authService.loginWithGoogle();

      if (!result.isSuccess) {
        _errorMessage = result.errorMessage;
      }

      return result.isSuccess;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void logout() {
    _authService.logout();
    notifyListeners();
  }
}