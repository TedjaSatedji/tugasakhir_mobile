import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool _isAuthenticated = false;
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isAuthenticated => _isAuthenticated;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.login(email, password);
      _isAuthenticated = token.isNotEmpty;
      _user = UserModel(
        id: '1',
        email: email,
        characterName: 'Hero',
        level: 1,
        totalXP: 0,
        totalSavings: 0,
        profileImageUrl: '',
        createdAt: DateTime.now(),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }

  Future<bool> checkBiometric() async {
    return await _authService.authenticateWithBiometric();
  }
}