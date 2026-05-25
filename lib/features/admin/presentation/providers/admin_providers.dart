import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../bootstrap.dart';
import '../../data/datasources/admin_local_datasource.dart';
import '../../data/datasources/mock_admin_remote_datasource.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../domain/entities/admin_entities.dart';
import '../../domain/repositories/admin_repository.dart';

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  return AdminLocalDataSource(ref.watch(appDatabaseProvider));
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(ref.watch(adminRemoteDataSourceProvider));
});

final adminUsersProvider = FutureProvider<List<AdminUser>>((ref) {
  return ref.watch(adminRepositoryProvider).getUsers();
});

final adminWalletsProvider = FutureProvider<List<AdminWallet>>((ref) {
  return ref.watch(adminRepositoryProvider).getWallets();
});
