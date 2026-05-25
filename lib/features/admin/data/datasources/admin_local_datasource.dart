import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/admin_entities.dart';
import 'mock_admin_remote_datasource.dart';

class AdminLocalDataSource implements AdminRemoteDataSource {
  AdminLocalDataSource(this._db);

  final db.AppDatabase _db;
  final Uuid _uuid = const Uuid();

  @override
  Future<List<AdminUser>> getUsers() async {
    final users = await (_db.select(
      _db.users,
    )..orderBy([(table) => OrderingTerm.asc(table.createdAt)])).get();
    final members = await _db.select(_db.walletMembers).get();

    return users
        .map((user) {
          final walletIds = members
              .where((member) => member.userId == user.id)
              .map((member) => member.walletId)
              .toList(growable: false);
          return AdminUser(
            id: user.id,
            name: user.name,
            phone: user.phone ?? '',
            role: _roleFromDb(user.role),
            isActive: user.isActive,
            walletIds: walletIds,
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<AdminWallet>> getWallets() async {
    final wallets = await (_db.select(
      _db.wallets,
    )..orderBy([(table) => OrderingTerm.asc(table.createdAt)])).get();
    return Future.wait(wallets.map(_mapWallet));
  }

  @override
  Future<AdminUser> createUser(CreateAdminUserRequest request) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await _db.transaction(() async {
      await _db
          .into(_db.users)
          .insert(
            db.UsersCompanion.insert(
              id: id,
              name: request.name.trim(),
              phone: Value(request.phone.trim()),
              role: request.role.value,
              isActive: const Value(true),
              createdAt: now,
              updatedAt: now,
            ),
          );
      if (request.role == AdminRole.owner) {
        await _insertOwnerMembers(
          userIdsByWalletId: {
            for (final walletId in request.walletIds) walletId: [id],
          },
          createdAt: now,
        );
      }
    });

    final users = await getUsers();
    return users.firstWhere((user) => user.id == id);
  }

  @override
  Future<AdminWallet> createWallet(CreateAdminWalletRequest request) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await _db.transaction(() async {
      await _db
          .into(_db.wallets)
          .insert(
            db.WalletsCompanion.insert(
              id: id,
              name: request.name.trim(),
              type: request.type,
              isActive: const Value(true),
              createdAt: now,
            ),
          );
      await _insertOwnerMembers(
        userIdsByWalletId: {id: request.ownerIds},
        createdAt: now,
      );
    });

    return _mapWalletById(id);
  }

  @override
  Future<AdminWallet> updateWallet(UpdateAdminWalletRequest request) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.update(
        _db.wallets,
      )..where((table) => table.id.equals(request.id))).write(
        db.WalletsCompanion(
          name: Value(request.name.trim()),
          type: Value(request.type),
        ),
      );
      await (_db.delete(_db.walletMembers)..where(
            (table) =>
                table.walletId.equals(request.id) & table.role.equals('owner'),
          ))
          .go();
      await _insertOwnerMembers(
        userIdsByWalletId: {request.id: request.ownerIds},
        createdAt: now,
      );
    });

    return _mapWalletById(request.id);
  }

  @override
  Future<void> setWalletActive({
    required String walletId,
    required bool isActive,
  }) async {
    await (_db.update(_db.wallets)..where((table) => table.id.equals(walletId)))
        .write(db.WalletsCompanion(isActive: Value(isActive)));
  }

  Future<void> _insertOwnerMembers({
    required Map<String, List<String>> userIdsByWalletId,
    required DateTime createdAt,
  }) async {
    for (final entry in userIdsByWalletId.entries) {
      for (final userId in entry.value.toSet()) {
        final exists =
            await (_db.select(_db.walletMembers)..where(
                  (table) =>
                      table.walletId.equals(entry.key) &
                      table.userId.equals(userId) &
                      table.role.equals('owner'),
                ))
                .getSingleOrNull();
        if (exists != null) {
          continue;
        }
        await _db
            .into(_db.walletMembers)
            .insert(
              db.WalletMembersCompanion.insert(
                id: _uuid.v4(),
                walletId: entry.key,
                userId: userId,
                role: 'owner',
                createdAt: Value(createdAt),
              ),
            );
      }
    }
  }

  Future<AdminWallet> _mapWalletById(String walletId) async {
    final wallet = await (_db.select(
      _db.wallets,
    )..where((table) => table.id.equals(walletId))).getSingle();
    return _mapWallet(wallet);
  }

  Future<AdminWallet> _mapWallet(db.Wallet wallet) async {
    final members =
        await (_db.select(_db.walletMembers)..where(
              (table) =>
                  table.walletId.equals(wallet.id) & table.role.equals('owner'),
            ))
            .get();
    final ownerIds = members
        .map((member) => member.userId)
        .toList(growable: false);
    final owners = ownerIds.isEmpty
        ? const <db.User>[]
        : await (_db.select(
            _db.users,
          )..where((table) => table.id.isIn(ownerIds))).get();

    return AdminWallet(
      id: wallet.id,
      name: wallet.name,
      type: wallet.type,
      owners: owners.map(_ownerDisplayName).toList(growable: false),
      ownerIds: ownerIds,
      balance: 0,
      isActive: wallet.isActive,
    );
  }

  AdminRole _roleFromDb(String role) {
    return AdminRole.values.firstWhere(
      (value) => value.value == role,
      orElse: () => AdminRole.assistant,
    );
  }

  String _ownerDisplayName(db.User user) {
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
