import 'package:bazar/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:bazar/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bazar/features/auth/data/models/user_model.dart';
import 'package:bazar/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bazar/features/auth/presentation/providers/auth_provider.dart';
import 'package:bazar/features/auth/presentation/screens/change_password_screen.dart';
import 'package:bazar/shared/models/app_enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('requires matching ten character password and submits change', (tester) async {
    final remote = _Remote();
    final repository = AuthRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: InMemoryAuthLocalDataSource(),
    );
    addTearDown(repository.dispose);
    final router = GoRouter(
      initialLocation: '/change-password',
      routes: [
        GoRoute(
          path: '/change-password',
          builder: (_, _) => const ChangePasswordScreen(),
        ),
        GoRoute(path: '/', builder: (_, _) => const SizedBox()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.enterText(find.byKey(const Key('current-password')), 'Temp123456');
    await tester.enterText(find.byKey(const Key('new-password')), 'short');
    await tester.enterText(find.byKey(const Key('confirm-password')), 'short');
    await tester.tap(find.text('পাসওয়ার্ড পরিবর্তন করুন'));
    await tester.pump();
    expect(find.text('কমপক্ষে ১০ অক্ষর দিন'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('new-password')), 'Permanent12');
    await tester.enterText(find.byKey(const Key('confirm-password')), 'Permanent12');
    await tester.tap(find.text('পাসওয়ার্ড পরিবর্তন করুন'));
    await tester.pump();
    expect(remote.changed, isTrue);
  });
}

class _Remote implements AuthRemoteDataSource {
  bool changed = false;
  static const user = UserModel(
    id: 'u1',
    name: 'User',
    role: UserRole.assistant,
    isActive: true,
  );

  @override
  Future<UserModel> changePassword({required String currentPassword, required String newPassword}) async {
    changed = true;
    return user;
  }

  @override
  Future<UserModel> getUserByToken(String token) async => user;
  @override
  Future<AuthRemoteResponse> login({required String phone, required String password}) async => const AuthRemoteResponse(token: 't', user: user);
  @override
  Future<void> logout() async {}
}
