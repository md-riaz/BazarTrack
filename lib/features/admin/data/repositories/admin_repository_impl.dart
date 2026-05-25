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

  @override
  Future<AdminWallet> createWallet(CreateAdminWalletRequest request) async {
    if (request.name.trim().isEmpty) {
      throw ArgumentError('ওয়ালেটের নাম আবশ্যক');
    }
    if (!adminWalletTypes.contains(request.type)) {
      throw ArgumentError('ওয়ালেটের ধরন সঠিক নয়');
    }
    if (request.ownerIds.isEmpty) {
      throw ArgumentError('কমপক্ষে একজন মালিক নির্বাচন করুন');
    }

    final users = await _remoteDataSource.getUsers();
    final assignableOwnerIds = users
        .where(
          (user) =>
              user.role == AdminRole.owner || user.role == AdminRole.admin,
        )
        .map((user) => user.id)
        .toSet();
    final hasInvalidOwner = request.ownerIds.any(
      (ownerId) => !assignableOwnerIds.contains(ownerId),
    );
    if (hasInvalidOwner) {
      throw ArgumentError('এক বা একাধিক মালিক সঠিক নয়');
    }

    return _remoteDataSource.createWallet(request);
  }
}
