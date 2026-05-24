import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login({required String phone, required String password});

  Future<void> logout();

  Future<bool> hasActiveSession();

  Future<User?> getCurrentUser();

  Stream<User?> watchCurrentUser();
}
