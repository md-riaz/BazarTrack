import '../../domain/entities/admin_entities.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/mock_admin_remote_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  const AdminRepositoryImpl(this._remoteDataSource);

  final AdminRemoteDataSource _remoteDataSource;

  @override
  Future<List<AdminUser>> getUsers() {
    return _remoteDataSource.getUsers();
  }

  @override
  Future<List<AdminWallet>> getWallets() {
    return _remoteDataSource.getWallets();
  }

  @override
  Future<AdminUser> createUser(CreateAdminUserRequest request) {
    if (request.name.trim().isEmpty || request.phone.trim().isEmpty) {
      throw ArgumentError('নাম ও ফোন নম্বর আবশ্যক');
    }
    return _remoteDataSource.createUser(request);
  }
}
