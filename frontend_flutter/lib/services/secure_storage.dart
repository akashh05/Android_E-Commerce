import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  // Secure storage instance
  static final _storage = FlutterSecureStorage();
  
  // Key used to store the auth token
  static const _tokenKey = 'auth_token';

  // Save the token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Retrieve the token
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Clear the token
  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
