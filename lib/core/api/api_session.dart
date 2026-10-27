import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiSessionStore {
  const ApiSessionStore(this._storage);

  static const tokenKey = 'auth_token';
  static const userIdKey = 'auth_user_id';

  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: tokenKey);

  Future<void> clear() async {
    await _storage.delete(key: tokenKey);
    await _storage.delete(key: userIdKey);
  }
}

class ApiSessionEvents {
  final _unauthorizedController = StreamController<void>.broadcast();

  Stream<void> get unauthorized => _unauthorizedController.stream;

  void notifyUnauthorized() => _unauthorizedController.add(null);

  Future<void> dispose() => _unauthorizedController.close();
}
