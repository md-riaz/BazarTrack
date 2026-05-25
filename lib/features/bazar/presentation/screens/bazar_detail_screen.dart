import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/app_enums.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/ghost_button.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../domain/entities/bazar_entities.dart';
import '../providers/bazar_providers.dart';
import '../widgets/activity_timeline_widget.dart';
import '../widgets/bazar_status_widgets.dart';
import '../widgets/item_edit_sheet.dart';

class BazarDetailScreen extends ConsumerWidget {
  const BazarDetailScreen({
    required this.bazarId,
    super.key,
    this.userId,
    this.onAddItemTap,
    this.onCommentsTap,
    this.onPriceHistoryTap,
  });

  final String bazarId;
  final String? userId;
  final VoidCallback? onAddItemTap;
  final VoidCallback? onCommentsTap;
  final VoidCallback? onPriceHistoryTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bazar = ref.watch(bazarProvider(bazarId));
    final items = ref.watch(bazarItemsProvider(bazarId));
    final activity = ref.watch(bazarActivityProvider(bazarId));
    final actionState = ref.watch(bazarActionControllerProvider);

    return bazar.when(
      data: (bazar) {
        if (bazar == null) {
          return const Scaffold(
            body: Center(child: Text('বাজার পাওয়া যায়নি')),
          );
        }
        return Scaffold(
          backgroundColor: AppColors.surface2,
          appBar: BazarAppBar(
            title: bazar.title ?? 'বাজার বিস্তারিত',
            subtitle: (bazar.walletName ?? bazar.walletId).toUpperCase(),
          ),
          body: items.when(
            data: (itemList) => ListView(
              padding: const EdgeInsets.only(bottom: 18),
              children: [
                _SummaryCard(bazar: bazar, items: itemList),
                _ActionCard(
                  onAddItemTap: onAddItemTap,
                  onCommentsTap: onCommentsTap,
                  onPriceHistoryTap: onPriceHistoryTap,
                ),
                const SectionHeader(title: 'আইটেম তালিকা'),
                ...itemList.map(
                  (item) => _ItemTile(
                    item: item,
                    onTap: bazar.isClosed
                        ? null
                        : () => ItemEditSheet.show(
                            context,
                            item: item,
                            userId: userId,
                          ),
                  ),
                ),
                const SectionHeader(title: 'কার্যক্রম'),
                activity.when(
                  data: (events) => ActivityTimelineWidget(events: events),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(error.toString()),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
            error: (error, _) => Center(child: Text(error.toString())),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    label: actionState.isLoading
                        ? 'শেষ হচ্ছে...'
                        : 'আজকের বাজার শেষ',
                    onPressed: bazar.isClosed || actionState.isLoading
                        ? null
                        : () => ref
                              .read(bazarActionControllerProvider.notifier)
                              .closeBazar(bazarId: bazarId, userId: userId),
                  ),
                  GhostButton(
                    label: 'বাতিল করুন',
                    foregroundColor: AppColors.negative,
                    borderColor: AppColors.negativeLight,
                    onPressed: bazar.isClosed ? null : () {},
                  ),
                ],
              ),
            ),
          ),
        );
      },
      error: (error, _) =>
          Scaffold(body: Center(child: Text(error.toString()))),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.bazar, required this.items});

  final Bazar bazar;
  final List<BazarItem> items;

  @override
  Widget build(BuildContext context) {
    final done = items.where((item) => item.status == ItemStatus.done).length;
    final notFound = items
        .where((item) => item.status == ItemStatus.notFound)
        .length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('আজকের বাজার', style: AppTextStyles.screenTitle),
              ),
              bazarStatusChip(bazar.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _SummaryMetric(label: 'কেনা হয়েছে', value: '$done'),
              _SummaryMetric(label: 'পাওয়া যায়নি', value: '$notFound'),
              _SummaryMetric(
                label: 'মোট খরচ',
                value: CurrencyFormatter.format(bazar.spent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    this.onAddItemTap,
    this.onCommentsTap,
    this.onPriceHistoryTap,
  });

  final VoidCallback? onAddItemTap;
  final VoidCallback? onCommentsTap;
  final VoidCallback? onPriceHistoryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _ActionButton(
            label: 'আইটেম যোগ',
            icon: Icons.add_shopping_cart,
            onTap: onAddItemTap,
          ),
          _ActionButton(
            label: 'কমেন্টস',
            icon: Icons.chat_bubble_outline,
            onTap: onCommentsTap,
          ),
          _ActionButton(
            label: 'দাম ইতিহাস',
            icon: Icons.history,
            onTap: onPriceHistoryTap,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                const SizedBox(height: 6),
                Text(label, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 3),
          Text(value, style: AppTextStyles.bodyStrong),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item, this.onTap});

  final BazarItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(item.name, style: AppTextStyles.bodyStrong),
        subtitle: Text(
          [
            item.quantityLabel,
            item.attributes,
            item.note,
          ].where((value) => value != null && value.isNotEmpty).join(' · '),
          style: AppTextStyles.bodySmall,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            itemStatusChip(item.status),
            if (item.price != null && item.price! > 0) ...[
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.format(item.price!),
                style: AppTextStyles.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
