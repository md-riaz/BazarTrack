import 'package:bazar/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:bazar/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bazar/features/auth/data/models/user_model.dart';
import 'package:bazar/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bazar/shared/models/app_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryAuthLocalDataSource localDataSource;
  late AuthRepositoryImpl repository;

  setUp(() {
    localDataSource = InMemoryAuthLocalDataSource();
    repository = AuthRepositoryImpl(
      remoteDataSource: const MockAuthRemoteDataSource(delay: Duration.zero),
      localDataSource: localDataSource,
    );
  });

  tearDown(() {
    repository.dispose();
  });

  test('demo role login stores matching user and token', () async {
    final cases =
        <({String phone, String userId, UserRole role, String token})>[
          (
            phone: MockAuthRemoteDataSource.demoAdminPhone,
            userId: 'u0',
            role: UserRole.admin,
            token: 'mock-auth-token-u0',
          ),
          (
            phone: MockAuthRemoteDataSource.demoOwnerPhone,
            userId: 'u3',
            role: UserRole.owner,
            token: 'mock-auth-token-u3',
          ),
          (
            phone: MockAuthRemoteDataSource.demoAssistantPhone,
            userId: 'u1',
            role: UserRole.assistant,
            token: 'mock-auth-token-u1',
          ),
        ];

    for (final testCase in cases) {
      await repository.logout();

      final user = await repository.login(
        phone: testCase.phone,
        password: MockAuthRemoteDataSource.demoPassword,
      );

      expect(user.id, testCase.userId);
      expect(user.role, testCase.role);
      expect(await localDataSource.readToken(), testCase.token);
      expect(await localDataSource.readUserId(), testCase.userId);
    }
  });

  test('fallback manual login still stores assistant session', () async {
    final user = await repository.login(phone: '01700000000', password: 'demo');

    expect(user.id, 'u1');
    expect(user.name, 'Rahim Uddin');
    expect(user.role, UserRole.assistant);
    expect(await localDataSource.readToken(), 'mock-auth-token-u1');
    expect(await localDataSource.readUserId(), 'u1');
  });

  test('getCurrentUser returns null when no token exists', () async {
    final user = await repository.getCurrentUser();

    expect(user, isNull);
    expect(await repository.hasActiveSession(), isFalse);
  });

  test('getCurrentUser token restore preserves selected role', () async {
    final cases = <({String token, String userId, UserRole role})>[
      (token: 'mock-auth-token-u0', userId: 'u0', role: UserRole.admin),
      (token: 'mock-auth-token-u3', userId: 'u3', role: UserRole.owner),
      (token: 'mock-auth-token-u1', userId: 'u1', role: UserRole.assistant),
    ];

    for (final testCase in cases) {
      await repository.logout();
      await localDataSource.saveSession(
        token: testCase.token,
        userId: testCase.userId,
      );

      final user = await repository.getCurrentUser();

      expect(user, isNotNull);
      expect(user!.id, testCase.userId);
      expect(user.role, testCase.role);
      expect(await repository.hasActiveSession(), isTrue);
    }
  });

  test('logout clears token and emits null current user', () async {
    await repository.login(phone: '01700000000', password: 'demo');

    await repository.logout();

    expect(await localDataSource.readToken(), isNull);
    expect(await localDataSource.readUserId(), isNull);
    expect(await repository.getCurrentUser(), isNull);
  });

  test('watchCurrentUser emits login and logout changes', () async {
    final emitted = <String?>[];
    final subscription = repository.watchCurrentUser().listen(
      (user) => emitted.add(user?.id),
    );

    await Future<void>.delayed(Duration.zero);
    await repository.login(phone: '01700000000', password: 'demo');
    await repository.logout();
    await Future<void>.delayed(Duration.zero);

    expect(emitted, [null, 'u1', null]);
    await subscription.cancel();
  });

  test('UserModel serializes role and optional fields', () {
    const model = UserModel(
      id: 'u9',
      name: 'Test User',
      role: UserRole.owner,
      isActive: true,
      phone: '010',
      email: 'test@example.com',
    );

    final restored = UserModel.fromJson(model.toJson());

    expect(restored.id, model.id);
    expect(restored.role, UserRole.owner);
    expect(restored.phone, '010');
  });
}
