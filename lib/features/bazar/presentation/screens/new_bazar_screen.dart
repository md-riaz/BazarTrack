import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/wallet/domain/entities/wallet.dart';
import '../../../../features/wallet/presentation/providers/wallet_providers.dart';
import '../../../../shared/models/app_enums.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/frequent_items_row.dart';
import '../../../../shared/widgets/ghost_button.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../domain/entities/bazar_entities.dart';
import '../providers/bazar_providers.dart';

enum _BazarInputMode { manual, text }

class NewBazarScreen extends ConsumerStatefulWidget {
  const NewBazarScreen({super.key, this.onBack, this.onCreated});

  final VoidCallback? onBack;
  final ValueChanged<String>? onCreated;

  @override
  ConsumerState<NewBazarScreen> createState() => _NewBazarScreenState();
}

class _NewBazarScreenState extends ConsumerState<NewBazarScreen> {
  final _titleController = TextEditingController(text: 'আজকের বাজার');
  final _noteController = TextEditingController();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _attributesController = TextEditingController();
  final _rawTextController = TextEditingController();
  final _manualItems = <CreateBazarItemInput>[];

  _BazarInputMode _mode = _BazarInputMode.manual;
  bool _showOptional = false;
  String? _selectedWalletId;

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _attributesController.dispose();
    _rawTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletListProvider);
    final frequentItems = ref.watch(frequentItemsProvider);
    final actionState = ref.watch(bazarActionControllerProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: BazarAppBar(
        title: 'নতুন বাজার',
        leading: IconButton(
          onPressed: widget.onBack ?? () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.surface),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 18),
        children: [
          _ModeSelector(
            mode: _mode,
            onChanged: (mode) => setState(() => _mode = mode),
          ),
          SectionHeader(title: 'Wallet'),
          wallets.when(
            data: (items) => _WalletSelector(
              wallets: items,
              selectedWalletId: _selectedWalletId,
              onChanged: (walletId) =>
                  setState(() => _selectedWalletId = walletId),
            ),
            error: (error, _) => _MessageCard(message: error.toString()),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
          SectionHeader(title: 'Frequent Items'),
          FrequentItemsRow(items: frequentItems, onTap: _handleFrequentItem),
          if (_mode == _BazarInputMode.manual) ...[
            SectionHeader(title: 'আইটেম যোগ করুন'),
            _Card(
              child: Column(
                children: [
                  _InputField(
                    controller: _nameController,
                    label: 'আইটেম নাম',
                    hint: 'যেমন: আলু',
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 10),
                  _OptionalToggle(
                    expanded: _showOptional,
                    collapsedLabel: 'পরিমাণ / ব্র্যান্ড (optional)',
                    expandedLabel: 'কম দেখুন',
                    onTap: () => setState(() => _showOptional = !_showOptional),
                  ),
                  if (_showOptional) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _InputField(
                            controller: _quantityController,
                            label: 'পরিমাণ',
                            hint: 'যেমন: ২',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _InputField(
                            controller: _unitController,
                            label: 'ইউনিট',
                            hint: 'কেজি / প্যাকেট',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _InputField(
                      controller: _attributesController,
                      label: 'ব্র্যান্ড / নোট',
                      hint: 'যেমন: দেশি, বড় সাইজ',
                    ),
                  ],
                  const SizedBox(height: 12),
                  GhostButton(
                    label: '+ তালিকায় যোগ করুন',
                    margin: EdgeInsets.zero,
                    foregroundColor: AppColors.primary,
                    borderColor: AppColors.primaryBorder,
                    onPressed: _addManualItem,
                  ),
                ],
              ),
            ),
            if (_manualItems.isNotEmpty) ...[
              SectionHeader(title: 'যোগ করা আইটেম'),
              _ItemPreviewList(
                items: _manualItems,
                onRemove: (index) =>
                    setState(() => _manualItems.removeAt(index)),
              ),
            ],
          ] else ...[
            SectionHeader(title: 'টেক্সট থেকে আইটেম'),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InputField(
                    controller: _rawTextController,
                    label: 'বাজারের তালিকা',
                    hint: 'আলু ২ কেজি\nডিম ১২টা\nদুধ ২ প্যাকেট',
                    maxLines: 7,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'প্রতি লাইনে একটি আইটেম লিখুন। পরিমাণ ও ইউনিট থাকলে স্বয়ংক্রিয়ভাবে ধরা হবে।',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
          SectionHeader(title: 'Optional'),
          _Card(
            child: Column(
              children: [
                _InputField(
                  controller: _titleController,
                  label: 'শিরোনাম',
                  hint: 'আজকের বাজার',
                ),
                const SizedBox(height: 10),
                _InputField(
                  controller: _noteController,
                  label: 'নোট',
                  hint: 'যেমন: জরুরি আইটেম আগে কিনবেন',
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              label: actionState.isLoading
                  ? 'তৈরি হচ্ছে...'
                  : 'বাজার তৈরি করুন →',
              onPressed: actionState.isLoading
                  ? null
                  : () => _submit(
                      status: BazarStatus.open,
                      userId: currentUser?.id,
                    ),
            ),
            GhostButton(
              label: 'Draft সংরক্ষণ করুন',
              onPressed: actionState.isLoading
                  ? null
                  : () => _submit(
                      status: BazarStatus.draft,
                      userId: currentUser?.id,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleFrequentItem(String text) {
    if (_mode == _BazarInputMode.text) {
      final existing = _rawTextController.text.trimRight();
      _rawTextController.text = existing.isEmpty ? text : '$existing\n$text';
      _rawTextController.selection = TextSelection.collapsed(
        offset: _rawTextController.text.length,
      );
      return;
    }

    final parsed = ref.read(autoParseServiceProvider).parseLine(text);
    if (parsed == null) return;
    setState(() => _manualItems.add(parsed));
  }

  void _addManualItem() {
    final item = _manualInputToItem();
    if (item == null) {
      _showSnack('আইটেম নাম লিখুন');
      return;
    }
    setState(() {
      _manualItems.add(item);
      _nameController.clear();
      _quantityController.clear();
      _unitController.clear();
      _attributesController.clear();
    });
  }

  CreateBazarItemInput? _manualInputToItem() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return null;
    return CreateBazarItemInput(
      name: name,
      rawText: name,
      quantity: _parseNumber(_quantityController.text),
      unit: _blankToNull(_unitController.text),
      attributes: _blankToNull(_attributesController.text),
    );
  }

  Future<void> _submit({required BazarStatus status, String? userId}) async {
    final wallets =
        ref.read(walletListProvider).valueOrNull ?? const <Wallet>[];
    final walletId =
        _selectedWalletId ?? (wallets.isEmpty ? null : wallets.first.id);
    if (walletId == null) {
      _showSnack('Wallet নির্বাচন করুন');
      return;
    }

    final items = _collectItems();
    if (items.isEmpty) {
      _showSnack('কমপক্ষে একটি আইটেম যোগ করুন');
      return;
    }

    final bazar = await ref
        .read(bazarActionControllerProvider.notifier)
        .createBazar(
          CreateBazarInput(
            walletId: walletId,
            createdBy: userId ?? 'u1',
            status: status,
            bazarDate: DateTime.now(),
            title: _blankToNull(_titleController.text),
            note: _blankToNull(_noteController.text),
            items: items,
          ),
        );
    if (!mounted) return;
    if (bazar == null) {
      _showSnack('বাজার তৈরি করা যায়নি');
      return;
    }
    widget.onCreated?.call(bazar.id);
    _showSnack(
      status == BazarStatus.draft
          ? 'Draft সংরক্ষণ হয়েছে'
          : 'বাজার তৈরি হয়েছে',
    );
  }

  List<CreateBazarItemInput> _collectItems() {
    if (_mode == _BazarInputMode.text) {
      return ref
          .read(autoParseServiceProvider)
          .parseLines(_rawTextController.text);
    }
    final pending = _manualInputToItem();
    if (pending == null) return List.unmodifiable(_manualItems);
    return List.unmodifiable([..._manualItems, pending]);
  }

  double? _parseNumber(String value) {
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

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onChanged});

  final _BazarInputMode mode;
  final ValueChanged<_BazarInputMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface3,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _ModeButton(
            label: 'একে একে',
            selected: mode == _BazarInputMode.manual,
            onTap: () => onChanged(_BazarInputMode.manual),
          ),
          _ModeButton(
            label: 'টেক্সট',
            selected: mode == _BazarInputMode.text,
            onTap: () => onChanged(_BazarInputMode.text),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.surface : AppColors.surface3,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.bodyStrong.copyWith(
              color: selected ? AppColors.primary : AppColors.text3,
            ),
          ),
        ),
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
      return const _MessageCard(message: 'কোনো Wallet নেই');
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

class _OptionalToggle extends StatelessWidget {
  const _OptionalToggle({
    required this.expanded,
    required this.collapsedLabel,
    required this.expandedLabel,
    required this.onTap,
  });

  final bool expanded;
  final String collapsedLabel;
  final String expandedLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            expanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            expanded ? expandedLabel : collapsedLabel,
            style: AppTextStyles.sectionAction,
          ),
        ],
      ),
    );
  }
}

class _ItemPreviewList extends StatelessWidget {
  const _ItemPreviewList({required this.items, required this.onRemove});

  final List<CreateBazarItemInput> items;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < items.length; index++)
          _Card(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(items[index].name, style: AppTextStyles.bodyStrong),
                      if ([
                            items[index].quantity?.toString(),
                            items[index].unit,
                            items[index].attributes,
                          ]
                          .where((value) => value != null && value.isNotEmpty)
                          .isNotEmpty)
                        Text(
                          [
                                items[index].quantity?.toString(),
                                items[index].unit,
                                items[index].attributes,
                              ]
                              .where(
                                (value) => value != null && value.isNotEmpty,
                              )
                              .join(' · '),
                          style: AppTextStyles.bodySmall,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => onRemove(index),
                  icon: const Icon(Icons.close, color: AppColors.negative),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      inputFormatters: keyboardType == null
          ? null
          : [FilteringTextInputFormatter.allow(RegExp(r'[0-9০-৯\.,]'))],
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
  });

  final Widget child;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
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

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _Card(child: Text(message, style: AppTextStyles.body));
  }
}
