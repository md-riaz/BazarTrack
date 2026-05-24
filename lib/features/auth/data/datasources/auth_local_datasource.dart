import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class AuthLocalDataSource {
  Future<void> saveSession({required String token, required String userId});

  Future<String?> readToken();

  Future<String?> readUserId();

  Future<void> clearSession();
}

class SecureStorageAuthLocalDataSource implements AuthLocalDataSource {
  const SecureStorageAuthLocalDataSource(this._storage);

  static const tokenKey = 'auth_token';
  static const userIdKey = 'auth_user_id';

  final FlutterSecureStorage _storage;

  @override
  Future<void> saveSession({
    required String token,
    required String userId,
  }) async {
    await _storage.write(key: tokenKey, value: token);
    await _storage.write(key: userIdKey, value: userId);
  }

  @override
  Future<String?> readToken() {
    return _storage.read(key: tokenKey);
  }

  @override
  Future<String?> readUserId() {
    return _storage.read(key: userIdKey);
  }

  @override
  Future<void> clearSession() async {
    await _storage.delete(key: tokenKey);
    await _storage.delete(key: userIdKey);
  }
}

class InMemoryAuthLocalDataSource implements AuthLocalDataSource {
  String? _token;
  String? _userId;

  @override
  Future<void> saveSession({
    required String token,
    required String userId,
  }) async {
    _token = token;
    _userId = userId;
  }

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<String?> readUserId() async => _userId;

  @override
  Future<void> clearSession() async {
    _token = null;
    _userId = null;
  }
}
