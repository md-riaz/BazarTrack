import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> login({required String phone, required String password});

  Future<User> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> logout();

  Future<bool> hasActiveSession();

  Future<User?> getCurrentUser();

  Stream<User?> watchCurrentUser();
}
