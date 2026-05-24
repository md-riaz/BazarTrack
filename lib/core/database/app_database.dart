import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get role => text()();
  TextColumn get passwordHash => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Wallets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 150)();
  TextColumn get type => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get createdBy => text().references(Users, #id).nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class WalletMembers extends Table {
  TextColumn get id => text()();
  TextColumn get walletId => text().references(Wallets, #id)();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get role => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class WalletAssistantRestrictions extends Table {
  TextColumn get id => text()();
  TextColumn get walletId => text().references(Wallets, #id)();
  @ReferenceName('restrictedWallets')
  TextColumn get assistantId => text().references(Users, #id)();
  @ReferenceName('createdWalletRestrictions')
  TextColumn get createdBy => text().references(Users, #id).nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Bazars extends Table {
  TextColumn get id => text()();
  TextColumn get walletId => text().references(Wallets, #id)();
  @ReferenceName('createdBazars')
  TextColumn get createdBy => text().references(Users, #id)();
  @ReferenceName('assignedBazars')
  TextColumn get assignedTo => text().references(Users, #id).nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get status => text()();
  DateTimeColumn get bazarDate => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get closedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class BazarItems extends Table {
  TextColumn get id => text()();
  TextColumn get bazarId => text().references(Bazars, #id)();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get rawText => text().nullable()();
  RealColumn get quantity => real().nullable()();
  TextColumn get unit => text().nullable()();
  TextColumn get attributes => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get status => text()();
  RealColumn get price => real().nullable()();
  TextColumn get addedBy => text().references(Users, #id).nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  List<Index> get indexes => [
    Index(
      'idx_bazar_items_bazar_status',
      'CREATE INDEX idx_bazar_items_bazar_status ON bazar_items (bazar_id, status)',
    ),
    Index(
      'idx_bazar_items_bazar_price',
      'CREATE INDEX idx_bazar_items_bazar_price ON bazar_items (bazar_id, price)',
    ),
  ];
}

class MoneyEntries extends Table {
  TextColumn get id => text()();
  TextColumn get walletId => text().references(Wallets, #id)();
  @ReferenceName('assistantMoneyEntries')
  TextColumn get assistantId => text().references(Users, #id)();
  TextColumn get bazarId => text().references(Bazars, #id).nullable()();
  TextColumn get type => text()();
  RealColumn get amount => real()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get entryDate => dateTime()();
  @ReferenceName('createdMoneyEntries')
  TextColumn get createdBy => text().references(Users, #id).nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  List<Index> get indexes => [
    Index(
      'idx_money_entries_wallet_assistant_date',
      'CREATE INDEX idx_money_entries_wallet_assistant_date ON money_entries (wallet_id, assistant_id, entry_date)',
    ),
    Index(
      'idx_money_entries_wallet_locked',
      'CREATE INDEX idx_money_entries_wallet_locked ON money_entries (wallet_id, is_locked)',
    ),
  ];
}

class DirectExpenses extends Table {
  TextColumn get id => text()();
  TextColumn get walletId => text().references(Wallets, #id)();
  @ReferenceName('assistantDirectExpenses')
  TextColumn get assistantId => text().references(Users, #id)();
  RealColumn get amount => real()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get entryDate => dateTime()();
  TextColumn get receiptUrl => text().nullable()();
  @ReferenceName('createdDirectExpenses')
  TextColumn get createdBy => text().references(Users, #id).nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class WalletSnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get walletId => text().references(Wallets, #id)();
  @ReferenceName('assistantWalletSnapshots')
  TextColumn get assistantId => text().references(Users, #id).nullable()();
  TextColumn get periodMonth => text().withLength(min: 7, max: 7)();
  RealColumn get openingBalance => real()();
  RealColumn get closingBalance => real()();
  TextColumn get snapshotHash => text().nullable()();
  @ReferenceName('closedWalletSnapshots')
  TextColumn get closedBy => text().references(Users, #id).nullable()();
  DateTimeColumn get closedAt => dateTime()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {walletId, assistantId, periodMonth},
  ];
}

class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get bazarId => text().references(Bazars, #id).nullable()();
  TextColumn get bazarItemId => text().references(BazarItems, #id).nullable()();
  TextColumn get moneyEntryId =>
      text().references(MoneyEntries, #id).nullable()();
  TextColumn get directExpenseId =>
      text().references(DirectExpenses, #id).nullable()();
  TextColumn get fileUrl => text()();
  TextColumn get fileType => text()();
  TextColumn get uploadedBy => text().references(Users, #id).nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Comments extends Table {
  TextColumn get id => text()();
  TextColumn get bazarId => text().references(Bazars, #id)();
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get message => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ActivityLogs extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().references(Users, #id).nullable()();
  TextColumn get action => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get oldValue => text().nullable()();
  TextColumn get newValue => text().nullable()();
  TextColumn get ipAddress => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  List<Index> get indexes => [
    Index(
      'idx_activity_logs_entity',
      'CREATE INDEX idx_activity_logs_entity ON activity_logs (entity_type, entity_id)',
    ),
  ];
}

class SyncQueueItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(
  tables: [
    Users,
    Wallets,
    WalletMembers,
    WalletAssistantRestrictions,
    Bazars,
    BazarItems,
    MoneyEntries,
    DirectExpenses,
    WalletSnapshots,
    Attachments,
    Comments,
    ActivityLogs,
    SyncQueueItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'bazar.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
