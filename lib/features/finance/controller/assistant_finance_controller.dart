import 'package:bazar_track/features/auth/service/auth_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../model/finance.dart';
import '../model/owner.dart';
import '../repository/assistant_finance_repo.dart';

class AssistantFinanceController extends GetxController {
  final AssistantFinanceRepo repo;
  final AuthService auth;
  static const _pageSize = 30;

  AssistantFinanceController({required this.repo, required this.auth});

  late int _assistantId;
  int get assistantId => _assistantId;
  set assistantId(int value) => _assistantId = value;

  var owners = <Owner>[].obs;

  // ── Balance ────────────────────────────────────────
  var balance = 0.0.obs;
  var isLoadingBalance = false.obs;

  // ── Pagination state ─────────────────────────────
  var transactions = <Finance>[].obs;
  var isInitialLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasMore = true.obs;

  // ── Filters ──────────────────────────────────────
  var filterType = RxnString();
  var filterFrom = Rxn<DateTime>();
  var filterTo = Rxn<DateTime>();
  var hasFilter = false.obs;
  var assignedToOwnerId = Rxn<int>();

  /// Public entry to (re)load everything and be awaited by RefreshIndicator.
  Future<void> refreshAll() async {
    isInitialLoading.value = true;
    try {
      await loadOwners();
      await _loadBalance();
      await _loadInitialTransactions();
    } finally {
      isInitialLoading.value = false;
    }
  }

  /// Legacy name kept for compatibility, but now awaited internally.
  Future<void> prepareAndLoadingPayments() => refreshAll();

  /// Loads the list of owners (safe).
  Future<List<Owner>> loadOwners() async {
    try {
      final ownerlist = await repo.getOwners();
      owners.assignAll(ownerlist);
      return ownerlist;
    } catch (e, st) {
      debugPrint('Error loading owners: $e\n$st');
      owners.clear();
      return <Owner>[];
    }
  }

  /// Loads balance safely.
  Future<void> _loadBalance() async {
    isLoadingBalance.value = true;
    try {
      balance.value = await repo.getWalletBalance(_assistantId);
    } catch (e, st) {
      debugPrint('Error loading balance: $e\n$st');
      balance.value = 0.0;
    } finally {
      isLoadingBalance.value = false;
    }
  }

  /// Reset pagination and load first page.
  Future<void> _loadInitialTransactions() async {
    hasMore.value = true;
    transactions.clear();
    await _fetchPage(reset: true);
  }

  /// Load more (pagination) — safe to call multiple times, guarded by flags.
  Future<void> loadMoreTransactions() async {
    if (!hasMore.value || isLoadingMore.value) return;
    isLoadingMore.value = true;
    try {
      await _fetchPage();
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Fetch a page from repo. Handles reset and error cases.
  Future<void> _fetchPage({bool reset = false}) async {
    final cursor = reset || transactions.isEmpty ? null : transactions.last.id;
    try {
      final page = await repo.getTransactions(
        userId: _assistantId,
        type: filterType.value,
        from: filterFrom.value,
        to: filterTo.value,
        limit: _pageSize,
        cursor: cursor,
      );

      if (reset) {
        transactions.value = page;
      } else {
        transactions.addAll(page);
      }

      if (page.length < _pageSize) {
        hasMore.value = false;
      }
    } catch (e, st) {
      debugPrint('Error fetching transactions page: $e\n$st');
      // on error, don't change `hasMore` so user can retry
    }
  }

  void setFilters({String? type, DateTime? from, DateTime? to}) {
    filterType.value = type;
    filterFrom.value = from;
    filterTo.value = to;
    hasFilter.value = type != null || from != null || to != null;
    // reload and await so UI can await refresh if needed
    _loadInitialTransactions();
  }

  void clearFilters() {
    filterType.value = null;
    filterFrom.value = null;
    filterTo.value = null;
    hasFilter.value = false;
    _loadInitialTransactions();
  }

  Future<void> addRefund(double amount) async {
    final f = Finance(
      userId: _assistantId,
      ownerId: assignedToOwnerId.value,
      amount: amount,
      type: 'wallet',
      createdAt: DateTime.now(),
    );
    try {
      await repo.createPayment(f);
      await _loadBalance();
      await _loadInitialTransactions();
    } catch (e) {
      rethrow;
    }
  }
}
