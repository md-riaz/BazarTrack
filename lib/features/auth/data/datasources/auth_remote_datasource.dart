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

  static const adminUser = UserModel(
    id: 'u0',
    name: 'Admin User',
    role: UserRole.admin,
    isActive: true,
    phone: demoAdminPhone,
    email: 'admin@example.com',
  );

  static const ownerUser = UserModel(
    id: 'u3',
    name: 'Mr. CEO',
    role: UserRole.owner,
    isActive: true,
    phone: demoOwnerPhone,
    email: 'ceo@example.com',
  );

  static const assistantUser = UserModel(
    id: 'u1',
    name: 'Rahim Uddin',
    role: UserRole.assistant,
    isActive: true,
    phone: demoAssistantPhone,
    email: 'rahim@example.com',
  );

  static const seededUser = assistantUser;
  static const seededToken = demoAssistantToken;

  static const demoAdminPhone = '01000-ADMIN';
  static const demoOwnerPhone = '01900-XXXXXX';
  static const demoAssistantPhone = '01711-XXXXXX';
  static const demoPassword = 'demo-pass';

  static const demoAdminToken = 'mock-auth-token-u0';
  static const demoOwnerToken = 'mock-auth-token-u3';
  static const demoAssistantToken = 'mock-auth-token-u1';

  static const _usersByToken = <String, UserModel>{
    demoAdminToken: adminUser,
    demoOwnerToken: ownerUser,
    demoAssistantToken: assistantUser,
  };

  static const _tokensByPhone = <String, String>{
    demoAdminPhone: demoAdminToken,
    'admin': demoAdminToken,
    demoOwnerPhone: demoOwnerToken,
    'owner': demoOwnerToken,
    demoAssistantPhone: demoAssistantToken,
    'assistant': demoAssistantToken,
  };

  final Duration delay;

  @override
  Future<AuthRemoteResponse> login({
    required String phone,
    required String password,
  }) async {
    await Future<void>.delayed(delay);
    final token = _tokensByPhone[phone.trim()] ?? demoAssistantToken;
    return AuthRemoteResponse(token: token, user: _usersByToken[token]!);
  }

  @override
  Future<UserModel> getUserByToken(String token) async {
    await Future<void>.delayed(delay);
    return _usersByToken[token] ?? seededUser;
  }
}
