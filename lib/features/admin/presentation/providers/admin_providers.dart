import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_providers.dart';
import '../../../../core/config/api_config.dart';
import '../../../api/data/bazar_api_data_sources.dart';
import '../../../../bootstrap.dart';
import '../../data/datasources/admin_local_datasource.dart';
import '../../data/datasources/mock_admin_remote_datasource.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../domain/entities/admin_entities.dart';
import '../../domain/repositories/admin_repository.dart';

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  final config = ref.watch(apiConfigProvider);
  if (config.enabled) {
    return ApiAdminRemoteDataSource(ref.watch(bazarApiClientProvider));
  }
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
