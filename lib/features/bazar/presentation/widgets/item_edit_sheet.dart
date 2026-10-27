import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/app_enums.dart';
import '../../../../shared/widgets/bottom_sheet_handle.dart';
import '../../../../shared/widgets/ghost_button.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/receipt_image.dart';
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
  final _imagePicker = ImagePicker();
  Uint8List? _receiptBytes;
  String? _receiptUrl;

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
    _receiptUrl = widget.item.receiptUrl;
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
            const SizedBox(height: 14),
            Row(
              children: [
                ReceiptImage(receiptUrl: _receiptUrl, size: 58),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : _pickReceipt,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(_receiptUrl == null ? 'রসিদ/ছবি যোগ করুন' : 'রসিদ পরিবর্তন করুন'),
                  ),
                ),
              ],
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

  Future<void> _pickReceipt() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1800,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('রসিদের ছবি ৫ MB-এর মধ্যে রাখুন')),
        );
      }
      return;
    }
    setState(() {
      _receiptBytes = bytes;
      _receiptUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    });
  }

  Future<void> _save(ItemStatus status) async {
    final quantity = double.tryParse(_quantityController.text.trim());
    final price = double.tryParse(_priceController.text.trim());
    final receiptBytes = _receiptBytes;
    if (receiptBytes != null) {
      final uploaded = await ref
          .read(bazarActionControllerProvider.notifier)
          .uploadReceipt(itemId: widget.item.id, imageBytes: receiptBytes);
      if (uploaded == null) return;
      _receiptUrl = uploaded;
    }
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
