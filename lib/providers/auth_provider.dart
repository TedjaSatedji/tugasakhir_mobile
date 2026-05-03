import 'package:flutter/material.dart';
import '../core/services/app_lock_service.dart';
import '../core/services/auth_service.dart';
import '../core/services/storage_service.dart';
import '../models/user_model.dart';
import '../services/local_database.dart';
import '../core/services/sync_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final AppLockService _appLockService = AppLockService();
  
  bool _isAuthenticated = false;
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;
  bool _lockEnabled = false;
  bool _isUnlocked = true;
  bool _biometricUnlockEnabled = false;

  bool get isAuthenticated => _isAuthenticated;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  bool get isLockEnabled => _lockEnabled;
  bool get isUnlocked => _isUnlocked;
  bool get isBiometricUnlockEnabled => _biometricUnlockEnabled;

  AuthProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    // Hydrate the userId cache from secure storage
    await StorageService().initialize();

    // Migrate any old data to the current user
    final userId = StorageService.currentUserId;
    if (userId != 'guest') {
      await LocalDatabase.instance.migrateOldUserData(userId);
    }

    final tokenValid = await _authService.isTokenValid();
    _isAuthenticated = tokenValid;
    _lockEnabled = await _appLockService.isLockEnabled();
    _biometricUnlockEnabled = await _appLockService.isBiometricEnabled();
    _isUnlocked = !_lockEnabled || !_isAuthenticated;
    _isInitialized = true;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _authService.login(email, password);
      _isAuthenticated = token.isNotEmpty;
      _isUnlocked = true;

      // Migrate old data to this user's email-based ID
      await LocalDatabase.instance.migrateOldUserData(StorageService.currentUserId);

      _user = UserModel(
        id: StorageService.currentUserId,
        email: email,
        characterName: 'Hero',
        level: 1,
        totalXP: 0,
        totalSavings: 0,
        profileImageUrl: '',
        createdAt: DateTime.now(),
      );

      // Trigger a background pull to hydrate local DB
      await SyncService().pullAll();
      
      // We will need to reload the providers after this,
      // which we can handle via callbacks or just by virtue of the widgets rebuilding.

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

  Future<bool> register(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.register(email, password);
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

  Future<bool> resendVerificationEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resendVerificationEmail(email);
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

  Future<bool> requestPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.requestPasswordReset(email);
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

  Future<bool> verifyResetCode(String email, String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.verifyResetCode(email, code);
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

  Future<bool> resetPassword(String email, String code, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email, code, newPassword);
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
    await StorageService().clearUserId();
    await _authService.logout();
    _isAuthenticated = false;
    _user = null;
    _isUnlocked = true;
    notifyListeners();
  }

  Future<bool> checkBiometric() async {
    return await _authService.authenticateWithBiometric();
  }

  Future<bool> enableQuickUnlock({
    required String pin,
    required bool enableBiometric,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _appLockService.setPin(pin);
      await _appLockService.setLockEnabled(true);
      await _appLockService.setBiometricEnabled(enableBiometric);
      _lockEnabled = true;
      _biometricUnlockEnabled = enableBiometric;
      _isUnlocked = true;
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

  Future<void> disableQuickUnlock() async {
    await _appLockService.clearPin();
    await _appLockService.setLockEnabled(false);
    await _appLockService.setBiometricEnabled(false);
    _lockEnabled = false;
    _biometricUnlockEnabled = false;
    _isUnlocked = true;
    notifyListeners();
  }

  Future<void> setBiometricUnlockEnabled(bool enabled) async {
    await _appLockService.setBiometricEnabled(enabled);
    _biometricUnlockEnabled = enabled;
    notifyListeners();
  }

  Future<bool> unlockWithPin(String pin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _appLockService.verifyPin(pin);
      if (!ok) {
        throw Exception('PIN salah');
      }
      _isUnlocked = true;
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

  Future<bool> unlockWithBiometric() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ok = await _authService.authenticateWithBiometric();
      if (!ok) {
        throw Exception('Biometric gagal');
      }
      _isUnlocked = true;
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

  void lock() {
    if (_lockEnabled && _isAuthenticated) {
      _isUnlocked = false;
      notifyListeners();
    }
  }
}