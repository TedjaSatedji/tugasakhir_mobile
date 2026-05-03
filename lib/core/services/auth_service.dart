import 'package:dio/dio.dart';
import 'package:local_auth/local_auth.dart';
import '../constants/api_constants.dart';
import 'api_client.dart';
import 'storage_service.dart';

class AuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final StorageService _storageService = StorageService();
  final Dio _dio = ApiClient().dio;

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
    try {
      final response = await _dio.post(
        ApiConstants.loginPath,
        data: {
          'email': email,
          'password': password,
        },
      );

      final token = response.data['access_token'] as String? ?? '';
      if (token.isEmpty) {
        throw Exception('Login failed');
      }

      await _storageService.saveToken(token);
      await _storageService.saveUserData('email', email);
      await _storageService.saveUserId(email); // Use email as per-user key

      return token;
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['detail']?.toString() ?? 'Login failed')
          : 'Login failed';
      throw Exception(message);
    }
  }

  Future<void> register(String email, String password) async {
    try {
      await _dio.post(
        ApiConstants.registerPath,
        data: {
          'email': email,
          'password': password,
        },
      );
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['detail']?.toString() ?? 'Register failed')
          : 'Register failed';
      throw Exception(message);
    }
  }

  Future<void> verifyEmail(String token) async {
    try {
      await _dio.get(
        ApiConstants.verifyEmailPath,
        queryParameters: {'token': token},
      );
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['detail']?.toString() ?? 'Verification failed')
          : 'Verification failed';
      throw Exception(message);
    }
  }

  Future<void> resendVerificationEmail(String email) async {
    try {
      await _dio.post(
        ApiConstants.resendVerificationPath,
        data: {'email': email},
      );
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['detail']?.toString() ?? 'Failed to resend verification email')
          : 'Failed to resend verification email';
      throw Exception(message);
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      await _dio.post(
        ApiConstants.requestPasswordResetPath,
        data: {
          'email': email,
        },
      );
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['detail']?.toString() ?? 'Reset request failed')
          : 'Reset request failed';
      throw Exception(message);
    }
  }

  Future<void> verifyResetCode(String email, String code) async {
    try {
      await _dio.post(
        ApiConstants.verifyResetCodePath,
        data: {
          'email': email,
          'code': code,
        },
      );
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['detail']?.toString() ?? 'Verification failed')
          : 'Verification failed';
      throw Exception(message);
    }
  }

  Future<void> resetPassword(String email, String code, String newPassword) async {
    try {
      await _dio.post(
        ApiConstants.resetPasswordPath,
        data: {
          'email': email,
          'code': code,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['detail']?.toString() ?? 'Reset failed')
          : 'Reset failed';
      throw Exception(message);
    }
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