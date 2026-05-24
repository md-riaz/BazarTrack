import 'package:bazar/features/admin/data/datasources/mock_admin_remote_datasource.dart';
import 'package:bazar/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:bazar/features/admin/domain/entities/admin_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminRepositoryImpl', () {
    test('loads prototype users and wallets', () async {
      final repository = AdminRepositoryImpl(MockAdminRemoteDataSource());

      final users = await repository.getUsers();
      final wallets = await repository.getWallets();

      expect(users, hasLength(6));
      expect(users.first.name, 'Rahim Uddin');
      expect(wallets, hasLength(3));
      expect(wallets[1].name, 'CEO Personal');
      expect(wallets[1].balance, -1200);
    });

    test('creates user and puts it first in mock list', () async {
      final repository = AdminRepositoryImpl(MockAdminRemoteDataSource());

      final created = await repository.createUser(
        const CreateAdminUserRequest(
          name: 'New Assistant',
          phone: '01700-000000',
          role: AdminRole.assistant,
        ),
      );
      final users = await repository.getUsers();

      expect(created.name, 'New Assistant');
      expect(created.isActive, isTrue);
      expect(users.first.name, 'New Assistant');
      expect(users, hasLength(7));
    });

    test('rejects blank name or phone', () async {
      final repository = AdminRepositoryImpl(MockAdminRemoteDataSource());

      expect(
        () => repository.createUser(
          const CreateAdminUserRequest(
            name: '',
            phone: '01700-000000',
            role: AdminRole.assistant,
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => repository.createUser(
          const CreateAdminUserRequest(
            name: 'New Assistant',
            phone: '',
            role: AdminRole.assistant,
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}
