import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/app_enums.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../domain/entities/bazar_entities.dart';
import '../providers/bazar_providers.dart';
import '../widgets/bazar_status_widgets.dart';

class BazarListScreen extends ConsumerWidget {
  const BazarListScreen({super.key, this.onBazarTap});

  final ValueChanged<String>? onBazarTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bazars = ref.watch(bazarsProvider);
    final selectedStatus = ref.watch(selectedBazarStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: const BazarAppBar(
        title: 'বাজার তালিকা',
        subtitle: 'সব বাজার এক জায়গায়',
      ),
      body: Column(
        children: [
          SizedBox(
            height: 58,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              children: [
                _FilterChip(
                  label: 'সব',
                  selected: selectedStatus == null,
                  status: null,
                ),
                _FilterChip(
                  label: 'চলতেছে',
                  selected: selectedStatus == BazarStatus.open,
                  status: BazarStatus.open,
                ),
                _FilterChip(
                  label: 'খোলা',
                  selected: selectedStatus == BazarStatus.draft,
                  status: BazarStatus.draft,
                ),
                _FilterChip(
                  label: 'শেষ',
                  selected: selectedStatus == BazarStatus.closed,
                  status: BazarStatus.closed,
                ),
                _FilterChip(
                  label: 'বাতিল',
                  selected: selectedStatus == BazarStatus.cancelled,
                  status: BazarStatus.cancelled,
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'সাম্প্রতিক বাজার'),
          Expanded(
            child: bazars.when(
              data: (items) => items.isEmpty
                  ? const Center(child: Text('কোনো বাজার নেই'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemBuilder: (context, index) => _BazarCard(
                        bazar: items[index],
                        onTap: () => onBazarTap?.call(items[index].id),
                      ),
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemCount: items.length,
                    ),
              error: (error, _) => Center(child: Text(error.toString())),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends ConsumerWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.status,
  });

  final String label;
  final bool selected;
  final BazarStatus? status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) =>
            ref.read(selectedBazarStatusProvider.notifier).state = status,
        selectedColor: AppColors.primary,
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: selected ? Colors.white : AppColors.text2,
          fontWeight: FontWeight.w700,
        ),
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.border),
      ),
    );
  }
}

class _BazarCard extends StatelessWidget {
  const _BazarCard({required this.bazar, this.onTap});

  final Bazar bazar;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      bazar.title ?? 'বাজার',
                      style: AppTextStyles.bodyStrong,
                    ),
                  ),
                  bazarStatusChip(bazar.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                bazar.walletName ?? bazar.walletId,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Metric(label: 'আইটেম', value: '${bazar.itemCount}'),
                  const SizedBox(width: 12),
                  _Metric(
                    label: 'খরচ',
                    value: CurrencyFormatter.format(bazar.spent),
                  ),
                  const Spacer(),
                  if (bazar.assignedName != null)
                    Text(bazar.assignedName!, style: AppTextStyles.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        Text(value, style: AppTextStyles.bodyStrong),
      ],
    );
  }
}
