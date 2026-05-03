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

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    final result = await _authService.login(email, password);
    _isLoading = false;
    if (!result.isSuccess) {
      _errorMessage = result.errorMessage;
    }
    notifyListeners();
    return result.isSuccess;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String address = '',
  }) async {
    _setLoading(true);
    _errorMessage = null;
    final result = await _authService.register(
      name: name, email: email, phone: phone, password: password, address: address,
    );
    _isLoading = false;
    if (!result.isSuccess) {
      _errorMessage = result.errorMessage;
    }
    notifyListeners();
    return result.isSuccess;
  }

  Future<String?> forgotPassword(String email) async {
    _setLoading(true);
    _errorMessage = null;
    final result = await _authService.forgotPassword(email);
    _isLoading = false;
    if (!result.isSuccess) {
      _errorMessage = result.errorMessage;
      notifyListeners();
      return null;
    }
    notifyListeners();
    return result.message;
  }

  Future<bool> updateProfile({
    required String name,
    required String phone,
    required String address,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    final result = await _authService.updateProfile(name: name, phone: phone, address: address);
    _isLoading = false;
    if (!result.isSuccess) {
      _errorMessage = result.errorMessage;
    }
    notifyListeners();
    return result.isSuccess;
  }

  void logout() {
    _authService.logout();
    notifyListeners();
  }
}
