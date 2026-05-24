import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return const MockAuthRemoteDataSource();
});

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return SecureStorageAuthLocalDataSource(
    ref.watch(flutterSecureStorageProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repository = AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
    localDataSource: ref.watch(authLocalDataSourceProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});

final currentUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).watchCurrentUser();
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref
      .watch(currentUserProvider)
      .maybeWhen(data: (user) => user != null, orElse: () => false);
});

class LoginController extends StateNotifier<AsyncValue<User?>> {
  LoginController(this._repository) : super(const AsyncData(null));

  final AuthRepository _repository;

  Future<User?> login({required String phone, required String password}) async {
    state = const AsyncLoading();
    try {
      final user = await _repository.login(phone: phone, password: password);
      state = AsyncData(user);
      return user;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await _repository.logout();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}

final loginControllerProvider =
    StateNotifierProvider<LoginController, AsyncValue<User?>>((ref) {
      return LoginController(ref.watch(authRepositoryProvider));
    });
