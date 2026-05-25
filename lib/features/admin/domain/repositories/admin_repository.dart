import '../entities/admin_entities.dart';

abstract class AdminRepository {
  Future<List<AdminUser>> getUsers();
  Future<List<AdminWallet>> getWallets();
  Future<AdminUser> createUser(CreateAdminUserRequest request);
  Future<AdminWallet> createWallet(CreateAdminWalletRequest request);
}
