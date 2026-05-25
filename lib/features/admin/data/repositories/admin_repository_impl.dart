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
    await _validateWalletRequest(
      name: request.name,
      type: request.type,
      ownerIds: request.ownerIds,
    );
    return _remoteDataSource.createWallet(request);
  }

  @override
  Future<AdminWallet> updateWallet(UpdateAdminWalletRequest request) async {
    await _validateWalletRequest(
      name: request.name,
      type: request.type,
      ownerIds: request.ownerIds,
    );
    return _remoteDataSource.updateWallet(request);
  }

  @override
  Future<void> setWalletActive({
    required String walletId,
    required bool isActive,
  }) {
    return _remoteDataSource.setWalletActive(
      walletId: walletId,
      isActive: isActive,
    );
  }

  Future<void> _validateWalletRequest({
    required String name,
    required String type,
    required List<String> ownerIds,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('ওয়ালেটের নাম আবশ্যক');
    }
    if (!adminWalletTypes.contains(type)) {
      throw ArgumentError('ওয়ালেটের ধরন সঠিক নয়');
    }
    if (ownerIds.isEmpty) {
      throw ArgumentError('কমপক্ষে একজন মালিক নির্বাচন করুন');
    }

    final users = await _remoteDataSource.getUsers();
    final assignableOwnerIds = users
        .where((user) => user.isActive && user.role == AdminRole.owner)
        .map((user) => user.id)
        .toSet();
    final hasInvalidOwner = ownerIds.any(
      (ownerId) => !assignableOwnerIds.contains(ownerId),
    );
    if (hasInvalidOwner) {
      throw ArgumentError('এক বা একাধিক মালিক সঠিক নয়');
    }
  }
}
