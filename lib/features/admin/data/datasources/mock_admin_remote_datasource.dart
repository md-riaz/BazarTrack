import '../../domain/entities/admin_entities.dart';

abstract class AdminRemoteDataSource {
  Future<List<AdminUser>> getUsers();
  Future<List<AdminWallet>> getWallets();
  Future<AdminUser> createUser(CreateAdminUserRequest request);
  Future<AdminWallet> createWallet(CreateAdminWalletRequest request);
  Future<AdminWallet> updateWallet(UpdateAdminWalletRequest request);
  Future<void> setWalletActive({
    required String walletId,
    required bool isActive,
  });
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
    final selectedOwners = _selectedOwners(request.ownerIds);

    final wallet = AdminWallet(
      id: 'w${_wallets.length + 1}',
      name: request.name.trim(),
      type: request.type,
      owners: selectedOwners.map(_ownerDisplayName).toList(growable: false),
      ownerIds: selectedOwners.map((owner) => owner.id).toList(growable: false),
      balance: 0,
    );
    _wallets.insert(0, wallet);
    return wallet;
  }

  @override
  Future<AdminWallet> updateWallet(UpdateAdminWalletRequest request) async {
    final index = _wallets.indexWhere((wallet) => wallet.id == request.id);
    if (index < 0) {
      throw ArgumentError('ওয়ালেট পাওয়া যায়নি');
    }
    final selectedOwners = _selectedOwners(request.ownerIds);
    final current = _wallets[index];
    final wallet = AdminWallet(
      id: current.id,
      name: request.name.trim(),
      type: request.type,
      owners: selectedOwners.map(_ownerDisplayName).toList(growable: false),
      ownerIds: selectedOwners.map((owner) => owner.id).toList(growable: false),
      balance: current.balance,
      isActive: current.isActive,
    );
    _wallets[index] = wallet;
    return wallet;
  }

  @override
  Future<void> setWalletActive({
    required String walletId,
    required bool isActive,
  }) async {
    final index = _wallets.indexWhere((wallet) => wallet.id == walletId);
    if (index < 0) {
      throw ArgumentError('ওয়ালেট পাওয়া যায়নি');
    }
    final current = _wallets[index];
    _wallets[index] = AdminWallet(
      id: current.id,
      name: current.name,
      type: current.type,
      owners: current.owners,
      ownerIds: current.ownerIds,
      balance: current.balance,
      isActive: isActive,
    );
  }

  List<AdminUser> _selectedOwners(List<String> ownerIds) {
    final selectedOwners = _users
        .where(
          (user) =>
              ownerIds.contains(user.id) &&
              (user.role == AdminRole.owner || user.role == AdminRole.admin),
        )
        .toList(growable: false);

    if (selectedOwners.length != ownerIds.toSet().length) {
      throw ArgumentError('এক বা একাধিক মালিক সঠিক নয়');
    }
    return selectedOwners;
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
