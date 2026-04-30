import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
  );

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
    await _storage.deleteAll();
  }
}