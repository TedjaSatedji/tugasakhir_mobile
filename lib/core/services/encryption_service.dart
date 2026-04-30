import 'package:crypto/crypto.dart';

class EncryptionService {
  // Simple encryption using SHA256 for password hashing
  String hashPassword(String password) {
    return sha256.convert(password.codeUnits).toString();
  }

  // Simple XOR encryption for basic data protection
  String encryptData(String plaintext, String key) {
    List<int> plainBytes = plaintext.codeUnits;
    List<int> keyBytes = key.codeUnits;
    List<int> encrypted = [];

    for (int i = 0; i < plainBytes.length; i++) {
      encrypted.add(plainBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return encrypted.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
  }

  // Decrypt XOR data
  String decryptData(String encryptedText, String key) {
    try {
      List<int> encryptedBytes = [];
      for (int i = 0; i < encryptedText.length; i += 2) {
        encryptedBytes
            .add(int.parse(encryptedText.substring(i, i + 2), radix: 16));
      }

      List<int> keyBytes = key.codeUnits;
      List<int> decrypted = [];

      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return String.fromCharCodes(decrypted);
    } catch (e) {
      return '';
    }
  }

  // MD5 hash untuk data validation
  String hashData(String data) {
    return sha256.convert(data.codeUnits).toString();
  }
}