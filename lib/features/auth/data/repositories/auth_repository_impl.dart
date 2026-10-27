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
    Stream<void>? unauthorizedEvents,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource {
    _unauthorizedSubscription = unauthorizedEvents?.listen((_) {
      unawaited(_clearLocalSession());
    });
  }

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final _currentUserController = StreamController<User?>.broadcast();
  StreamSubscription<void>? _unauthorizedSubscription;

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
    Object? remoteError;
    try {
      if (await _localDataSource.readToken() case final token?
          when token.isNotEmpty) {
        try {
          await _remoteDataSource.logout();
        } catch (error) {
          remoteError = error;
        }
      }
      await _clearLocalSession();
    } catch (_) {
      throw const AuthFailure('লগআউট করা যায়নি। আবার চেষ্টা করুন।');
    }
    if (remoteError != null) {
      throw const AuthFailure(
        'এই ডিভাইস থেকে লগআউট হয়েছে, তবে সার্ভারে token revoke নিশ্চিত করা যায়নি।',
      );
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
    unawaited(_unauthorizedSubscription?.cancel());
    _currentUserController.close();
  }

  Future<void> _clearLocalSession() async {
    await _localDataSource.clearSession();
    _setCurrentUser(null);
  }

  void _setCurrentUser(User? user) {
    _cachedUser = user;
    if (!_isDisposed) {
      _currentUserController.add(user);
    }
  }
}
