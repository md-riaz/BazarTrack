import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/wallet/domain/entities/wallet.dart';
import '../../../../features/wallet/presentation/providers/wallet_providers.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_header.dart';
import '../providers/direct_expense_providers.dart';

class DirectExpenseScreen extends ConsumerStatefulWidget {
  const DirectExpenseScreen({super.key, this.onBack, this.onSaved});

  final VoidCallback? onBack;
  final VoidCallback? onSaved;

  @override
  ConsumerState<DirectExpenseScreen> createState() =>
      _DirectExpenseScreenState();
}

class _DirectExpenseScreenState extends ConsumerState<DirectExpenseScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _entryDate = DateTime.now();
  bool _hasReceipt = false;
  String? _selectedWalletId;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletListProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final actionState = ref.watch(directExpenseControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: BazarAppBar(
        title: 'সরাসরি খরচ',
        subtitle: 'BAZAR ছাড়া খরচ',
        leading: IconButton(
          onPressed: widget.onBack ?? () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.surface),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 18),
        children: [
          const _InfoCard(),
          SectionHeader(title: 'Wallet'),
          wallets.when(
            data: (items) => _WalletSelector(
              wallets: items,
              selectedWalletId: _selectedWalletId,
              onChanged: (walletId) =>
                  setState(() => _selectedWalletId = walletId),
            ),
            error: (error, _) =>
                _Card(child: Text(error.toString(), style: AppTextStyles.body)),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
          SectionHeader(title: 'খরচের তথ্য'),
          _Card(
            child: Column(
              children: [
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9০-৯০-৯\.,]'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'টাকার পরিমাণ',
                    hintText: 'যেমন: ১২০',
                    prefixText: '৳ ',
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'খরচের বিবরণ',
                    hintText: 'যেমন: রিকশাভাড়া, বাজারের ব্যাগ',
                  ),
                ),
              ],
            ),
          ),
          SectionHeader(title: 'তারিখ ও রসিদ'),
          _Card(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('তারিখ', style: AppTextStyles.bodyStrong),
                  subtitle: Text(
                    _dateLabel(_entryDate),
                    style: AppTextStyles.bodySmall,
                  ),
                  trailing: const Icon(
                    Icons.calendar_today,
                    color: AppColors.primary,
                  ),
                  onTap: _pickDate,
                ),
                const Divider(color: AppColors.border),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _hasReceipt,
                  activeThumbColor: AppColors.primary,
                  title: Text(
                    'রসিদ / ছবি আছে',
                    style: AppTextStyles.bodyStrong,
                  ),
                  subtitle: Text(
                    'এই ধাপে mock attachment flag রাখা হচ্ছে',
                    style: AppTextStyles.bodySmall,
                  ),
                  onChanged: (value) => setState(() => _hasReceipt = value),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: PrimaryButton(
          label: actionState.isLoading ? 'সংরক্ষণ হচ্ছে...' : 'সংরক্ষণ করুন',
          color: _parseAmount(_amountController.text) == null
              ? AppColors.border2
              : AppColors.primary,
          onPressed: actionState.isLoading
              ? null
              : () => _submit(userId: currentUser?.id),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (selected == null) return;
    setState(() => _entryDate = selected);
  }

  Future<void> _submit({String? userId}) async {
    final wallets =
        ref.read(walletListProvider).valueOrNull ?? const <Wallet>[];
    final walletId =
        _selectedWalletId ?? (wallets.isEmpty ? null : wallets.first.id);
    if (walletId == null) {
      _showSnack('Wallet নির্বাচন করুন');
      return;
    }
    final amount = _parseAmount(_amountController.text);
    if (amount == null || amount <= 0) {
      _showSnack('সঠিক টাকার পরিমাণ লিখুন');
      return;
    }
    final actorId = userId ?? 'u1';
    final expense = await ref
        .read(directExpenseControllerProvider.notifier)
        .createDirectExpense(
          walletId: walletId,
          assistantId: actorId,
          amount: amount,
          entryDate: _entryDate,
          note: _blankToNull(_noteController.text),
          receiptUrl: _hasReceipt ? 'mock://receipt/direct-expense' : null,
          createdBy: actorId,
        );
    if (!mounted) return;
    if (expense == null) {
      _showSnack('খরচ সংরক্ষণ করা যায়নি');
      return;
    }
    _showSnack('সরাসরি খরচ সংরক্ষণ হয়েছে');
    widget.onSaved?.call();
  }

  double? _parseAmount(String value) {
    final normalized = value
        .trim()
        .replaceAll('০', '0')
        .replaceAll('১', '1')
        .replaceAll('২', '2')
        .replaceAll('৩', '3')
        .replaceAll('৪', '4')
        .replaceAll('৫', '5')
        .replaceAll('৬', '6')
        .replaceAll('৭', '7')
        .replaceAll('৮', '8')
        .replaceAll('৯', '9')
        .replaceAll(',', '.');
    return normalized.isEmpty ? null : double.tryParse(normalized);
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _dateLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning),
      ),
      child: Text(
        'এটি Bazar তালিকা ছাড়া সরাসরি খরচ।',
        style: AppTextStyles.bodyStrong.copyWith(color: AppColors.warningDark),
      ),
    );
  }
}

class _WalletSelector extends StatelessWidget {
  const _WalletSelector({
    required this.wallets,
    required this.selectedWalletId,
    required this.onChanged,
  });

  final List<Wallet> wallets;
  final String? selectedWalletId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (wallets.isEmpty) {
      return _Card(child: Text('কোনো Wallet নেই', style: AppTextStyles.body));
    }
    final value = wallets.any((wallet) => wallet.id == selectedWalletId)
        ? selectedWalletId
        : wallets.first.id;
    return _Card(
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: const InputDecoration(labelText: 'Wallet নির্বাচন করুন'),
        items: wallets
            .map(
              (wallet) =>
                  DropdownMenuItem(value: wallet.id, child: Text(wallet.name)),
            )
            .toList(growable: false),
        onChanged: onChanged,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
