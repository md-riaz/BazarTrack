import '../../../../shared/models/app_enums.dart';
import '../models/user_model.dart';

class AuthRemoteResponse {
  const AuthRemoteResponse({required this.token, required this.user});

  final String token;
  final UserModel user;
}

abstract class AuthRemoteDataSource {
  Future<AuthRemoteResponse> login({
    required String phone,
    required String password,
  });

  Future<UserModel> getUserByToken(String token);
}

class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  const MockAuthRemoteDataSource({
    this.delay = const Duration(milliseconds: 350),
  });

  static const seededUser = UserModel(
    id: 'u1',
    name: 'Rahim Uddin',
    role: UserRole.assistant,
    isActive: true,
    phone: '01711-XXXXXX',
    email: 'rahim@example.com',
  );

  static const seededToken = 'mock-auth-token-u1';

  final Duration delay;

  @override
  Future<AuthRemoteResponse> login({
    required String phone,
    required String password,
  }) async {
    await Future<void>.delayed(delay);
    return const AuthRemoteResponse(token: seededToken, user: seededUser);
  }

  @override
  Future<UserModel> getUserByToken(String token) async {
    await Future<void>.delayed(delay);
    return seededUser;
  }
}
