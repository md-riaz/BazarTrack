import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/app_enums.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../reports/presentation/providers/report_providers.dart';
import '../../../wallet/domain/entities/wallet_summary.dart';
import '../../../wallet/presentation/providers/wallet_providers.dart';
import '../../domain/entities/money_entry.dart';
import '../providers/money_providers.dart';
import '../widgets/pending_return_requests.dart';

class MoneyEntryScreen extends ConsumerStatefulWidget {
  const MoneyEntryScreen({super.key});

  @override
  ConsumerState<MoneyEntryScreen> createState() => _MoneyEntryScreenState();
}

class _MoneyEntryScreenState extends ConsumerState<MoneyEntryScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  EntryType _type = EntryType.moneyReceived;
  bool _isSaving = false;
  String? _selectedAccountId;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final effectiveType = currentUser?.role == UserRole.assistant
        ? EntryType.moneyReturned
        : EntryType.moneyReceived;
    if (_type != effectiveType) _type = effectiveType;
    final summaries = ref.watch(walletSummariesProvider);
    final availableAccounts =
        summaries.valueOrNull
            ?.where((summary) => summary.accountId != null)
            .toList(growable: false) ??
        const <WalletSummary>[];
    final selected = availableAccounts.cast<WalletSummary?>().firstWhere(
      (summary) => summary?.accountId == _selectedAccountId,
      orElse: () => availableAccounts.isEmpty ? null : availableAccounts.first,
    );
    final accountId = selected?.accountId;
    final entries = accountId == null
        ? const AsyncValue<List<MoneyEntry>>.data([])
        : ref.watch(
            moneyEntriesProvider(MoneyEntryFilter(walletId: accountId)),
          );

    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: BazarAppBar(
        title: 'টাকা এন্ট্রি',
        leading: Navigator.canPop(context)
            ? IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: DropdownButtonFormField<String>(
              initialValue: selected?.accountId,
              decoration: const InputDecoration(labelText: 'Fund account'),
              items: [
                for (final summary in availableAccounts)
                  DropdownMenuItem(
                    value: summary.accountId,
                    child: Text(summary.wallet.name),
                  ),
              ],
              onChanged: (value) => setState(() => _selectedAccountId = value),
            ),
          ),
          _EntryFormCard(
            selectedType: _type,
            amountController: _amountController,
            noteController: _noteController,
            availableTypes: currentUser?.role == UserRole.assistant
                ? const [EntryType.moneyReturned]
                : const [EntryType.moneyReceived],
            onTypeChanged: (type) => setState(() => _type = type),
          ),
          PrimaryButton(
            label: _isSaving ? 'সংরক্ষণ হচ্ছে...' : 'সংরক্ষণ করুন',
            onPressed: _isSaving || accountId == null
                ? null
                : () => _save(selected!),
          ),
          const PendingReturnRequests(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('সাম্প্রতিক এন্ট্রি', style: AppTextStyles.screenTitle),
          ),
          const SizedBox(height: 10),
          entries.when(
            data: (items) => items.isEmpty
                ? const _EmptyEntries()
                : Column(children: items.take(6).map(_EntryTile.new).toList()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => const _EntryError(),
          ),
        ],
      ),
    );
  }

  Future<void> _save(WalletSummary selection) async {
    final amount = double.tryParse(_amountController.text.trim());
    final note = _noteController.text.trim();
    if (amount == null || amount == 0) {
      _showMessage('সঠিক পরিমাণ লিখুন');
      return;
    }
    if (_type == EntryType.adjustment && note.isEmpty) {
      _showMessage('সমন্বয়ের কারণ লিখুন');
      return;
    }

    final accountId = selection.accountId;
    final assistantId = selection.assistantId;
    final actorId = ref.read(currentUserProvider).valueOrNull?.id;
    if (accountId == null || assistantId == null || actorId == null) {
      _showMessage('সঠিক account বা session পাওয়া যায়নি');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(moneyEntryRepositoryProvider)
          .createMoneyEntry(
            walletId: accountId,
            assistantId: assistantId,
            type: _type,
            amount: amount,
            entryDate: DateTime.now(),
            note: note.isEmpty ? null : note,
            createdBy: actorId,
          );
      ref.invalidate(moneyEntriesProvider);
      ref.invalidate(walletSummariesProvider);
      ref.invalidate(monthlyReportProvider(currentPeriodMonth()));
      _amountController.clear();
      _noteController.clear();
      _showMessage(
        _type == EntryType.moneyReturned
            ? 'ফেরত অনুরোধ পাঠানো হয়েছে; ম্যানেজার নিশ্চিত করলে ব্যালেন্স বদলাবে'
            : 'টাকা এন্ট্রি সংরক্ষণ হয়েছে',
      );
    } catch (_) {
      _showMessage('টাকা এন্ট্রি সংরক্ষণ করা যায়নি');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EntryFormCard extends StatelessWidget {
  const _EntryFormCard({
    required this.selectedType,
    required this.amountController,
    required this.noteController,
    required this.availableTypes,
    required this.onTypeChanged,
  });

  final EntryType selectedType;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final List<EntryType> availableTypes;
  final ValueChanged<EntryType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('এন্ট্রি টাইপ', style: AppTextStyles.label),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableTypes
                .map(
                  (type) => ChoiceChip(
                    label: Text(_labelFor(type)),
                    selected: selectedType == type,
                    selectedColor: AppColors.primaryLight,
                    onSelected: (_) => onTypeChanged(type),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          Text('পরিমাণ (৳)', style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(hintText: 'যেমন ৫০০০'),
          ),
          const SizedBox(height: 16),
          Text(
            selectedType == EntryType.adjustment
                ? 'কারণ লিখুন (প্রয়োজনীয়)'
                : 'নোট',
            style: AppTextStyles.label,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: noteController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'ঐচ্ছিক নোট'),
          ),
        ],
      ),
    );
  }

  String _labelFor(EntryType type) {
    return switch (type) {
      EntryType.moneyReceived => 'ফান্ড থেকে দিলাম',
      EntryType.moneyReturned => 'ফেরত নিশ্চিত করলাম',
      EntryType.adjustment => 'সমন্বয়',
    };
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile(this.entry);

  final MoneyEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = entry.signedAmount >= 0
        ? AppColors.positive
        : AppColors.negative;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: entry.signedAmount >= 0
                ? AppColors.positiveLight
                : AppColors.negativeLight,
            child: Icon(
              entry.signedAmount >= 0
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.label, style: AppTextStyles.bodyStrong),
                if ((entry.note ?? '').isNotEmpty)
                  Text(entry.note!, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(entry.signedAmount),
            style: AppTextStyles.bodyStrong.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _EmptyEntries extends StatelessWidget {
  const _EmptyEntries();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text('এখনও কোনো টাকা এন্ট্রি নেই', style: AppTextStyles.body),
    );
  }
}

class _EntryError extends StatelessWidget {
  const _EntryError();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text('টাকা এন্ট্রি লোড করা যায়নি', style: AppTextStyles.body),
    );
  }
}
