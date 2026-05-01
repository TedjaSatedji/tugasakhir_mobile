import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
  );

  /// Cached current user ID, available synchronously after [initialize].
  static String? _cachedUserId;
  static String get currentUserId => _cachedUserId ?? 'guest';

  /// Call once at app startup (after login check) to hydrate the cache.
  Future<void> initialize() async {
    _cachedUserId = await _storage.read(key: 'user_id');
  }

  Future<void> saveUserId(String userId) async {
    _cachedUserId = userId;
    await _storage.write(key: 'user_id', value: userId);
  }

  Future<void> clearUserId() async {
    _cachedUserId = null;
    await _storage.delete(key: 'user_id');
  }

  // Save JWT Token
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  // Get JWT Token
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // Delete Token
  Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  // Save User Data
  Future<void> saveUserData(String key, String value) async {
    await _storage.write(key: 'user_$key', value: value);
  }

  // Get User Data
  Future<String?> getUserData(String key) async {
    return await _storage.read(key: 'user_$key');
  }

  // Delete All
  Future<void> deleteAll() async {
    _cachedUserId = null;
    await _storage.deleteAll();
  }
}