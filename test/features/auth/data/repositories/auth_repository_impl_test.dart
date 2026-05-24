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

  test('login succeeds with seeded mock user and stores token', () async {
    final user = await repository.login(phone: '01700000000', password: 'demo');

    expect(user.id, 'u1');
    expect(user.name, 'Rahim Uddin');
    expect(user.role, UserRole.assistant);
    expect(
      await localDataSource.readToken(),
      MockAuthRemoteDataSource.seededToken,
    );
    expect(await localDataSource.readUserId(), 'u1');
  });

  test('getCurrentUser returns null when no token exists', () async {
    final user = await repository.getCurrentUser();

    expect(user, isNull);
    expect(await repository.hasActiveSession(), isFalse);
  });

  test('getCurrentUser restores seeded user when token exists', () async {
    await localDataSource.saveSession(
      token: MockAuthRemoteDataSource.seededToken,
      userId: 'u1',
    );

    final user = await repository.getCurrentUser();

    expect(user, isNotNull);
    expect(user!.id, 'u1');
    expect(await repository.hasActiveSession(), isTrue);
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
