import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/app_enums.dart';
import '../../../../shared/widgets/bottom_sheet_handle.dart';
import '../../../../shared/widgets/ghost_button.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/entities/bazar_entities.dart';
import '../providers/bazar_providers.dart';

class ItemEditSheet extends ConsumerStatefulWidget {
  const ItemEditSheet({required this.item, super.key, this.userId});

  final BazarItem item;
  final String? userId;

  static Future<void> show(
    BuildContext context, {
    required BazarItem item,
    String? userId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ItemEditSheet(item: item, userId: userId),
    );
  }

  @override
  ConsumerState<ItemEditSheet> createState() => _ItemEditSheetState();
}

class _ItemEditSheetState extends ConsumerState<ItemEditSheet> {
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  late final TextEditingController _priceController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.item.quantity?.toString() ?? '',
    );
    _unitController = TextEditingController(text: widget.item.unit ?? '');
    _priceController = TextEditingController(
      text: widget.item.price?.toString() ?? '',
    );
    _noteController = TextEditingController(text: widget.item.note ?? '');
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(bazarActionControllerProvider);
    final isLoading = actionState.isLoading;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BottomSheetHandle(),
            Text(widget.item.name, style: AppTextStyles.screenTitle),
            if (widget.item.rawText != null) ...[
              const SizedBox(height: 4),
              Text(widget.item.rawText!, style: AppTextStyles.bodySmall),
            ],
            const SizedBox(height: 16),
            Text('কতটুকু কিনলেন?', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(hintText: 'পরিমাণ'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _unitController,
                    decoration: const InputDecoration(hintText: 'ইউনিট'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('দাম কত হলো? (৳)', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(hintText: '০'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(hintText: 'নোট'),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: isLoading ? 'সেভ হচ্ছে...' : '✓ কেনা হয়েছে',
              onPressed: isLoading ? null : () => _save(ItemStatus.done),
              margin: EdgeInsets.zero,
            ),
            GhostButton(
              label: '✕ পাওয়া যায়নি',
              foregroundColor: AppColors.negative,
              borderColor: AppColors.negativeLight,
              onPressed: isLoading ? null : () => _save(ItemStatus.notFound),
              margin: const EdgeInsets.only(top: 8, bottom: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(ItemStatus status) async {
    final quantity = double.tryParse(_quantityController.text.trim());
    final price = double.tryParse(_priceController.text.trim());
    await ref
        .read(bazarActionControllerProvider.notifier)
        .updateItem(
          itemId: widget.item.id,
          quantity: quantity,
          unit: _unitController.text.trim().isEmpty
              ? null
              : _unitController.text.trim(),
          price: status == ItemStatus.notFound ? 0 : price,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          status: status,
          userId: widget.userId,
        );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
