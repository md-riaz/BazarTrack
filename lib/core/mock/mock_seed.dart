import 'package:drift/drift.dart';

import '../database/app_database.dart';

class MockSeed {
  MockSeed._();

  static const frequentItems = <String>[
    'দুধ ২ প্যাকেট',
    'ডিম ৩০টা',
    'পাউরুটি ৩টা',
    'মুরগি ১ কেজি',
    'চাল ৫ কেজি',
    'ডাল ১ কেজি',
    'সয়াবিন তেল',
    'পেঁয়াজ ১ কেজি',
  ];

  static Future<void> seed(AppDatabase db) async {
    final existing = await db.select(db.users).get();
    if (existing.isNotEmpty) {
      return;
    }

    final now = DateTime(2025, 5, 23, 12);
    final yesterday = now.subtract(const Duration(days: 1));

    await db.batch((batch) {
      batch.insertAll(db.users, [
        UsersCompanion.insert(
          id: 'u1',
          name: 'Rahim Uddin',
          phone: const Value('01711-XXXXXX'),
          email: const Value('rahim@example.com'),
          role: 'assistant',
          passwordHash: const Value('demo-hash'),
          isActive: const Value(true),
          createdAt: now,
          updatedAt: now,
        ),
        UsersCompanion.insert(
          id: 'u2',
          name: 'Karim Sheikh',
          phone: const Value('01812-XXXXXX'),
          email: const Value('karim@example.com'),
          role: 'assistant',
          passwordHash: const Value('demo-hash'),
          isActive: const Value(true),
          createdAt: now,
          updatedAt: now,
        ),
        UsersCompanion.insert(
          id: 'u3',
          name: 'Mr. CEO',
          phone: const Value('01900-XXXXXX'),
          email: const Value('ceo@example.com'),
          role: 'owner',
          passwordHash: const Value('demo-hash'),
          isActive: const Value(true),
          createdAt: now,
          updatedAt: now,
        ),
        UsersCompanion.insert(
          id: 'u4',
          name: 'Fatema (Accounts)',
          phone: const Value('01613-XXXXXX'),
          email: const Value('fatema@example.com'),
          role: 'owner',
          passwordHash: const Value('demo-hash'),
          isActive: const Value(true),
          createdAt: now,
          updatedAt: now,
        ),
        UsersCompanion.insert(
          id: 'u5',
          name: 'Sabbir Ahmed',
          phone: const Value('01714-XXXXXX'),
          email: const Value('sabbir@example.com'),
          role: 'assistant',
          passwordHash: const Value('demo-hash'),
          isActive: const Value(false),
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      batch.insertAll(db.wallets, [
        WalletsCompanion.insert(
          id: 'w1',
          name: 'Office Wallet',
          type: 'shared',
          isActive: const Value(true),
          createdBy: const Value('u4'),
          createdAt: now,
        ),
        WalletsCompanion.insert(
          id: 'w2',
          name: 'CEO Personal',
          type: 'personal',
          isActive: const Value(true),
          createdBy: const Value('u3'),
          createdAt: now,
        ),
        WalletsCompanion.insert(
          id: 'w3',
          name: 'CTO Personal',
          type: 'personal',
          isActive: const Value(true),
          createdBy: const Value('u4'),
          createdAt: now,
        ),
      ]);

      batch.insertAll(db.walletMembers, [
        WalletMembersCompanion.insert(id: 'wm1', walletId: 'w1', userId: 'u4', role: 'owner'),
        WalletMembersCompanion.insert(id: 'wm2', walletId: 'w2', userId: 'u3', role: 'owner'),
        WalletMembersCompanion.insert(id: 'wm3', walletId: 'w3', userId: 'u4', role: 'owner'),
      ]);

      batch.insertAll(db.bazars, [
        BazarsCompanion.insert(
          id: 'b1',
          walletId: 'w2',
          createdBy: 'u3',
          assignedTo: const Value('u1'),
          title: const Value('CEO Personal বাজার'),
          note: const Value('আজকের বাজার'),
          status: 'open',
          bazarDate: now,
          createdAt: now.subtract(const Duration(hours: 2)),
          updatedAt: now,
        ),
        BazarsCompanion.insert(
          id: 'b2',
          walletId: 'w1',
          createdBy: 'u4',
          assignedTo: const Value.absent(),
          title: const Value('Office Wallet বাজার'),
          note: const Value('যে কেউ নিতে পারবে'),
          status: 'draft',
          bazarDate: now,
          createdAt: now.subtract(const Duration(hours: 1)),
          updatedAt: now,
        ),
        BazarsCompanion.insert(
          id: 'b3',
          walletId: 'w3',
          createdBy: 'u4',
          assignedTo: const Value('u2'),
          title: const Value('CTO Personal বাজার'),
          note: const Value('গতকালের বাজার'),
          status: 'closed',
          bazarDate: yesterday,
          createdAt: yesterday.subtract(const Duration(hours: 3)),
          updatedAt: yesterday,
          closedAt: Value(yesterday.add(const Duration(hours: 4))),
        ),
      ]);

      batch.insertAll(db.bazarItems, [
        BazarItemsCompanion.insert(
          id: 'i1',
          bazarId: 'b1',
          name: 'পাউরুটি',
          rawText: const Value('পাউরুটি ৩টা'),
          quantity: const Value(3),
          unit: const Value('টা'),
          attributes: const Value(''),
          note: const Value(''),
          status: 'done',
          price: const Value(180),
          addedBy: const Value('u1'),
          createdAt: now.subtract(const Duration(hours: 1, minutes: 45)),
          updatedAt: now.subtract(const Duration(minutes: 15)),
        ),
        BazarItemsCompanion.insert(
          id: 'i2',
          bazarId: 'b1',
          name: 'গরুর মাংস',
          rawText: const Value('গরুর মাংস ২ কেজি'),
          quantity: const Value(2),
          unit: const Value('কেজি'),
          attributes: const Value(''),
          note: const Value('বাজারে ছিল না'),
          status: 'not_found',
          addedBy: const Value('u1'),
          createdAt: now.subtract(const Duration(hours: 1, minutes: 35)),
          updatedAt: now.subtract(const Duration(minutes: 40)),
        ),
        BazarItemsCompanion.insert(
          id: 'i3',
          bazarId: 'b1',
          name: 'দুধ',
          rawText: const Value('দুধ ২ প্যাকেট'),
          quantity: const Value(2),
          unit: const Value('প্যাকেট'),
          attributes: const Value('Aarong'),
          note: const Value(''),
          status: 'pending',
          addedBy: const Value('u1'),
          createdAt: now.subtract(const Duration(hours: 1, minutes: 20)),
          updatedAt: now.subtract(const Duration(minutes: 28)),
        ),
        BazarItemsCompanion.insert(
          id: 'i4',
          bazarId: 'b1',
          name: 'ডিম',
          rawText: const Value('ডিম ৩০টা'),
          quantity: const Value(30),
          unit: const Value('টা'),
          attributes: const Value(''),
          note: const Value(''),
          status: 'pending',
          addedBy: const Value('u1'),
          createdAt: now.subtract(const Duration(hours: 1, minutes: 5)),
          updatedAt: now.subtract(const Duration(minutes: 20)),
        ),
      ]);

      batch.insertAll(db.moneyEntries, [
        MoneyEntriesCompanion.insert(
          id: 'm1',
          walletId: 'w1',
          assistantId: 'u1',
          type: 'money_received',
          amount: 10000,
          note: const Value('Office Wallet fund'),
          entryDate: now,
          createdBy: const Value('u4'),
          createdAt: now,
          updatedAt: now,
        ),
        MoneyEntriesCompanion.insert(
          id: 'm2',
          walletId: 'w2',
          assistantId: 'u1',
          bazarId: const Value('b1'),
          type: 'money_received',
          amount: 5000,
          note: const Value('CEO Personal advance'),
          entryDate: now,
          createdBy: const Value('u3'),
          createdAt: now,
          updatedAt: now,
        ),
        MoneyEntriesCompanion.insert(
          id: 'm3',
          walletId: 'w3',
          assistantId: 'u2',
          type: 'money_received',
          amount: 3000,
          note: const Value('CTO Personal advance'),
          entryDate: yesterday,
          createdBy: const Value('u4'),
          createdAt: yesterday,
          updatedAt: yesterday,
        ),
        MoneyEntriesCompanion.insert(
          id: 'm4',
          walletId: 'w1',
          assistantId: 'u1',
          type: 'money_returned',
          amount: 1200,
          note: const Value('Returned after close'),
          entryDate: now,
          createdBy: const Value('u1'),
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      batch.insertAll(db.directExpenses, [
        DirectExpensesCompanion.insert(
          id: 'd1',
          walletId: 'w2',
          assistantId: 'u1',
          amount: 50,
          note: const Value('সরাসরি খরচ'),
          entryDate: now,
          receiptUrl: const Value(''),
          createdBy: const Value('u1'),
          createdAt: now,
        ),
      ]);

      batch.insertAll(db.walletSnapshots, [
        WalletSnapshotsCompanion.insert(
          id: 's1',
          walletId: 'w1',
          periodMonth: '2025-05',
          openingBalance: 0,
          closingBalance: 800,
          snapshotHash: const Value('demo-hash-office'),
          closedBy: const Value('u4'),
          closedAt: now,
          notes: const Value('Office Wallet snapshot'),
        ),
        WalletSnapshotsCompanion.insert(
          id: 's2',
          walletId: 'w2',
          assistantId: const Value('u1'),
          periodMonth: '2025-05',
          openingBalance: 0,
          closingBalance: -1200,
          snapshotHash: const Value('demo-hash-ceo'),
          closedBy: const Value('u3'),
          closedAt: now,
          notes: const Value('CEO snapshot'),
        ),
      ]);

      batch.insertAll(db.comments, [
        CommentsCompanion.insert(
          id: 'c1',
          bazarId: 'b1',
          userId: 'u1',
          message: 'Aarong পাইনি, local brand দেখছি',
          createdAt: now.subtract(const Duration(minutes: 22)),
        ),
      ]);

      batch.insertAll(db.activityLogs, [
        ActivityLogsCompanion.insert(
          id: 'a1',
          userId: const Value('u1'),
          action: 'item.purchased',
          entityType: 'bazar_item',
          entityId: 'i1',
          oldValue: const Value('{"status":"pending"}'),
          newValue: const Value('{"status":"done","price":180}'),
          createdAt: now.subtract(const Duration(minutes: 15)),
        ),
        ActivityLogsCompanion.insert(
          id: 'a2',
          userId: const Value('u1'),
          action: 'item.not_found',
          entityType: 'bazar_item',
          entityId: 'i2',
          oldValue: const Value('{"status":"pending"}'),
          newValue: const Value('{"status":"not_found"}'),
          createdAt: now.subtract(const Duration(minutes: 40)),
        ),
        ActivityLogsCompanion.insert(
          id: 'a3',
          userId: const Value('u3'),
          action: 'item.updated',
          entityType: 'bazar_item',
          entityId: 'i3',
          oldValue: const Value('{"quantity":3}'),
          newValue: const Value('{"quantity":2}'),
          createdAt: now.subtract(const Duration(hours: 1, minutes: 28)),
        ),
        ActivityLogsCompanion.insert(
          id: 'a4',
          userId: const Value('u1'),
          action: 'bazar.started',
          entityType: 'bazar',
          entityId: 'b1',
          newValue: const Value('{"items":4}'),
          createdAt: now.subtract(const Duration(hours: 1, minutes: 45)),
        ),
      ]);

      batch.insertAll(db.syncQueueItems, [
        SyncQueueItemsCompanion.insert(
          entityType: 'bazar_item',
          entityId: 'i3',
          operation: 'update',
          payload: '{"name":"দুধ ২ প্যাকেট","status":"waiting"}',
          createdAt: now.subtract(const Duration(minutes: 3)),
        ),
        SyncQueueItemsCompanion.insert(
          entityType: 'bazar_item',
          entityId: 'i4',
          operation: 'update',
          payload: '{"name":"ডিম ৩০টা","status":"not_found"}',
          createdAt: now.subtract(const Duration(minutes: 5)),
        ),
        SyncQueueItemsCompanion.insert(
          entityType: 'direct_expense',
          entityId: 'd1',
          operation: 'create',
          payload: '{"entity":"সরাসরি খরচ — ৳ ৫০"}',
          createdAt: now.subtract(const Duration(minutes: 8)),
          retryCount: const Value(1),
        ),
      ]);
    });
  }
}
