import '../../domain/entities/admin_entities.dart';

abstract class AdminRemoteDataSource {
  Future<List<AdminUser>> getUsers();
  Future<List<AdminWallet>> getWallets();
  Future<AdminUser> createUser(CreateAdminUserRequest request);
  Future<AdminWallet> createWallet(CreateAdminWalletRequest request);
}

class MockAdminRemoteDataSource implements AdminRemoteDataSource {
  MockAdminRemoteDataSource()
    : _users = List<AdminUser>.from(_seedUsers),
      _wallets = List<AdminWallet>.from(_seedWallets);

  final List<AdminUser> _users;
  final List<AdminWallet> _wallets;

  static const _seedUsers = <AdminUser>[
    AdminUser(
      id: 'u1',
      name: 'Rahim Uddin',
      phone: '01711-XXXXXX',
      role: AdminRole.assistant,
      isActive: true,
    ),
    AdminUser(
      id: 'u2',
      name: 'Karim Sheikh',
      phone: '01812-XXXXXX',
      role: AdminRole.assistant,
      isActive: true,
    ),
    AdminUser(
      id: 'u3',
      name: 'Mr. CEO',
      phone: '01900-XXXXXX',
      role: AdminRole.owner,
      isActive: true,
    ),
    AdminUser(
      id: 'u6',
      name: 'Mr. CTO',
      phone: '01901-XXXXXX',
      role: AdminRole.owner,
      isActive: true,
    ),
    AdminUser(
      id: 'u4',
      name: 'Fatema (Accounts)',
      phone: '01613-XXXXXX',
      role: AdminRole.owner,
      isActive: true,
    ),
    AdminUser(
      id: 'u5',
      name: 'Sabbir Ahmed',
      phone: '01714-XXXXXX',
      role: AdminRole.assistant,
      isActive: false,
    ),
  ];

  static const _seedWallets = <AdminWallet>[
    AdminWallet(
      id: 'w1',
      name: 'Office Wallet',
      type: 'shared',
      owners: ['Fatema'],
      balance: 800,
    ),
    AdminWallet(
      id: 'w2',
      name: 'CEO Personal',
      type: 'personal',
      owners: ['CEO'],
      balance: -1200,
    ),
    AdminWallet(
      id: 'w3',
      name: 'CTO Personal',
      type: 'personal',
      owners: ['CTO'],
      balance: 0,
    ),
  ];

  @override
  Future<List<AdminUser>> getUsers() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List<AdminUser>.unmodifiable(_users);
  }

  @override
  Future<List<AdminWallet>> getWallets() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List<AdminWallet>.unmodifiable(_wallets);
  }

  @override
  Future<AdminUser> createUser(CreateAdminUserRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final user = AdminUser(
      id: 'u${_users.length + 1}',
      name: request.name,
      phone: request.phone,
      role: request.role,
      isActive: true,
    );
    _users.insert(0, user);
    return user;
  }

  @override
  Future<AdminWallet> createWallet(CreateAdminWalletRequest request) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final selectedOwners = _users
        .where(
          (user) =>
              request.ownerIds.contains(user.id) &&
              (user.role == AdminRole.owner || user.role == AdminRole.admin),
        )
        .toList(growable: false);

    if (selectedOwners.length != request.ownerIds.toSet().length) {
      throw ArgumentError('এক বা একাধিক মালিক সঠিক নয়');
    }

    final wallet = AdminWallet(
      id: 'w${_wallets.length + 1}',
      name: request.name.trim(),
      type: request.type,
      owners: selectedOwners.map(_ownerDisplayName).toList(growable: false),
      balance: 0,
    );
    _wallets.insert(0, wallet);
    return wallet;
  }

  String _ownerDisplayName(AdminUser user) {
    final name = user.name.trim();
    if (name.startsWith('Mr. ')) {
      return name.substring(4);
    }
    final parenthesisStart = name.indexOf(' (');
    if (parenthesisStart > 0) {
      return name.substring(0, parenthesisStart);
    }
    return name;
  }
}
