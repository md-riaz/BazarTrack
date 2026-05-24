import 'dart:async';

import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final _currentUserController = StreamController<User?>.broadcast();

  User? _cachedUser;
  bool _isDisposed = false;

  @override
  Future<User> login({required String phone, required String password}) async {
    try {
      final response = await _remoteDataSource.login(
        phone: phone,
        password: password,
      );
      await _localDataSource.saveSession(
        token: response.token,
        userId: response.user.id,
      );
      _setCurrentUser(response.user);
      return response.user;
    } catch (_) {
      throw const AuthFailure('লগইন করা যায়নি। আবার চেষ্টা করুন।');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _localDataSource.clearSession();
      _setCurrentUser(null);
    } catch (_) {
      throw const AuthFailure('লগআউট করা যায়নি। আবার চেষ্টা করুন।');
    }
  }

  @override
  Future<bool> hasActiveSession() async {
    try {
      final token = await _localDataSource.readToken();
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    if (_cachedUser != null) {
      return _cachedUser;
    }

    try {
      final token = await _localDataSource.readToken();
      if (token == null || token.isEmpty) {
        _setCurrentUser(null);
        return null;
      }

      final user = await _remoteDataSource.getUserByToken(token);
      _setCurrentUser(user);
      return user;
    } catch (_) {
      await _localDataSource.clearSession();
      _setCurrentUser(null);
      return null;
    }
  }

  @override
  Stream<User?> watchCurrentUser() async* {
    yield await getCurrentUser();
    yield* _currentUserController.stream;
  }

  void dispose() {
    _isDisposed = true;
    _currentUserController.close();
  }

  void _setCurrentUser(User? user) {
    _cachedUser = user;
    if (!_isDisposed) {
      _currentUserController.add(user);
    }
  }
}
