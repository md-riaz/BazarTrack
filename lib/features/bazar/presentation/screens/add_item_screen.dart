import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/frequent_items_row.dart';
import '../../../../shared/widgets/ghost_button.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../domain/entities/bazar_entities.dart';
import '../providers/bazar_providers.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({
    required this.bazarId,
    super.key,
    this.onBack,
    this.onDone,
  });

  final String bazarId;
  final VoidCallback? onBack;
  final VoidCallback? onDone;

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _attributesController = TextEditingController();
  final _noteController = TextEditingController();
  final _addedItems = <CreateBazarItemInput>[];
  bool _showOptional = false;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _attributesController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bazar = ref.watch(bazarProvider(widget.bazarId));
    final frequentItems = ref.watch(frequentItemsProvider);
    final actionState = ref.watch(bazarActionControllerProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    final subtitle = bazar.valueOrNull == null
        ? 'বাজার'
        : (bazar.valueOrNull!.walletName ?? bazar.valueOrNull!.walletId)
              .toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: BazarAppBar(
        title: 'আইটেম যোগ করুন',
        subtitle: subtitle,
        leading: IconButton(
          onPressed: widget.onBack ?? () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.surface),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 18),
        children: [
          SectionHeader(title: 'Frequent Items'),
          FrequentItemsRow(
            items: frequentItems,
            onTap: (text) => _addParsedItem(text, userId: currentUser?.id),
          ),
          SectionHeader(title: 'নতুন আইটেম'),
          _Card(
            child: Column(
              children: [
                _InputField(
                  controller: _nameController,
                  label: 'আইটেম নাম',
                  hint: 'যেমন: আলু',
                ),
                const SizedBox(height: 10),
                _OptionalToggle(
                  expanded: _showOptional,
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
                          hint: '২',
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
                          hint: 'কেজি',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _InputField(
                    controller: _attributesController,
                    label: 'ব্র্যান্ড / ধরন',
                    hint: 'যেমন: দেশি, বড়',
                  ),
                  const SizedBox(height: 10),
                  _InputField(
                    controller: _noteController,
                    label: 'নোট',
                    hint: 'যেমন: না পেলে কল করবেন',
                    maxLines: 2,
                  ),
                ],
              ],
            ),
          ),
          if (_addedItems.isNotEmpty) ...[
            SectionHeader(title: 'এখন যোগ হয়েছে'),
            for (final item in _addedItems)
              _Card(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(item.name, style: AppTextStyles.bodyStrong),
              ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: GhostButton(
                label: '+ আরেকটি',
                margin: const EdgeInsets.fromLTRB(16, 4, 6, 8),
                foregroundColor: AppColors.primary,
                borderColor: AppColors.primaryBorder,
                onPressed: actionState.isLoading
                    ? null
                    : () => _submit(clearAfter: true, userId: currentUser?.id),
              ),
            ),
            Expanded(
              child: PrimaryButton(
                label: actionState.isLoading ? 'যোগ হচ্ছে...' : '✓ শেষ করুন',
                margin: const EdgeInsets.fromLTRB(6, 4, 16, 8),
                onPressed: actionState.isLoading
                    ? null
                    : () => _submit(clearAfter: false, userId: currentUser?.id),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addParsedItem(String rawText, {String? userId}) async {
    final item = ref.read(autoParseServiceProvider).parseLine(rawText);
    if (item == null) return;
    await _createItem(item, clearAfter: true, userId: userId);
  }

  Future<void> _submit({required bool clearAfter, String? userId}) async {
    final item = _inputToItem();
    if (item == null) {
      _showSnack('আইটেম নাম লিখুন');
      return;
    }
    await _createItem(item, clearAfter: clearAfter, userId: userId);
    if (!clearAfter && mounted) {
      widget.onDone?.call();
    }
  }

  Future<void> _createItem(
    CreateBazarItemInput item, {
    required bool clearAfter,
    String? userId,
  }) async {
    final created = await ref
        .read(bazarActionControllerProvider.notifier)
        .addItem(bazarId: widget.bazarId, item: item, userId: userId);
    if (!mounted) return;
    if (created == null) {
      _showSnack('আইটেম যোগ করা যায়নি');
      return;
    }
    setState(() => _addedItems.add(item));
    if (clearAfter) {
      _clearForm();
      _showSnack('আইটেম যোগ হয়েছে');
    }
  }

  CreateBazarItemInput? _inputToItem() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return null;
    return CreateBazarItemInput(
      name: name,
      rawText: name,
      quantity: _parseNumber(_quantityController.text),
      unit: _blankToNull(_unitController.text),
      attributes: _blankToNull(_attributesController.text),
      note: _blankToNull(_noteController.text),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _quantityController.clear();
    _unitController.clear();
    _attributesController.clear();
    _noteController.clear();
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

class _OptionalToggle extends StatelessWidget {
  const _OptionalToggle({required this.expanded, required this.onTap});

  final bool expanded;
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
            expanded
                ? 'optional fields লুকান'
                : 'পরিমাণ, ইউনিট, ব্র্যান্ড যোগ করুন (optional)',
            style: AppTextStyles.sectionAction,
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: keyboardType == null
          ? null
          : [FilteringTextInputFormatter.allow(RegExp(r'[0-9০-৯০-৯\.,]'))],
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
