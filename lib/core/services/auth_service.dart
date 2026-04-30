import 'package:local_auth/local_auth.dart';
import 'storage_service.dart';

class AuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final StorageService _storageService = StorageService();

  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Gunakan biometric untuk akses Vault',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  Future<String> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));
    
    String token =
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
    
    await _storageService.saveToken(token);
    await _storageService.saveUserData('email', email);
    
    return token;
  }

  Future<void> logout() async {
    await _storageService.deleteAll();
  }

  Future<String?> getToken() async {
    return await _storageService.getToken();
  }

  Future<bool> isTokenValid() async {
    final token = await _storageService.getToken();
    return token != null;
  }
}