import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, this.onBack, this.onOfflineQueueTap});

  final VoidCallback? onBack;
  final VoidCallback? onOfflineQueueTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(settingsNotificationProvider);
    final sound = ref.watch(settingsSoundProvider);
    final bangla = ref.watch(settingsBanglaProvider);
    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: BazarAppBar(
        title: 'সেটিংস',
        leading: BackButton(onPressed: onBack),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 12),
          const HLabel('নোটিফিকেশন'),
          HSectionCard(
            children: [
              HMenuRow(
                title: 'পুশ নোটিফিকেশন',
                subtitle: 'বাজার ও টাকার আপডেট',
                trailing: HSwitch(
                  semanticLabel: 'পুশ নোটিফিকেশন',
                  value: notifications,
                  onChanged: (value) =>
                      ref.read(settingsNotificationProvider.notifier).state =
                          value,
                ),
              ),
              HMenuRow(
                title: 'শব্দ',
                subtitle: 'নোটিফিকেশন শব্দ',
                showDivider: false,
                trailing: HSwitch(
                  semanticLabel: 'শব্দ',
                  value: sound,
                  onChanged: (value) =>
                      ref.read(settingsSoundProvider.notifier).state = value,
                ),
              ),
            ],
          ),
          const HLabel('ভাষা / Language'),
          HSectionCard(
            children: [
              _LanguageRow(
                label: 'বাংলা',
                selected: bangla,
                onTap: () =>
                    ref.read(settingsBanglaProvider.notifier).state = true,
              ),
              _LanguageRow(
                label: 'English',
                selected: !bangla,
                showDivider: false,
                onTap: () =>
                    ref.read(settingsBanglaProvider.notifier).state = false,
              ),
            ],
          ),
          const HLabel('ডেটা ও Storage'),
          HSectionCard(
            children: [
              const HMenuRow(
                title: 'Local cache clear করুন',
                subtitle: 'Offline ডাটা মুছে যাবে',
              ),
              HMenuRow(
                title: 'Sync queue দেখুন',
                subtitle: 'Pending items',
                titleColor: AppColors.primary,
                showDivider: false,
                onTap: onOfflineQueueTap,
              ),
            ],
          ),
          const HLabel('App info'),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Column(
              children: [
                _InfoRow(label: 'Version', value: '1.0.0 (MVP)'),
                SizedBox(height: 8),
                _InfoRow(label: 'Build', value: '2025.05.23'),
                SizedBox(height: 8),
                _InfoRow(label: 'Backend', value: 'api.bazarkhata.com'),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.showDivider = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: AppColors.surface3))
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border2,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Text(label, style: AppTextStyles.bodyStrong),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(value, style: AppTextStyles.bodyStrong.copyWith(fontSize: 12)),
      ],
    );
  }
}
