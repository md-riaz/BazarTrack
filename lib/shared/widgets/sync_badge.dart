import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/app_enums.dart';

class SyncBadge extends StatelessWidget {
  const SyncBadge({required this.status, super.key});

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final data = switch (status) {
      SyncStatus.online => ('✓', 'Synced', AppColors.positive),
      SyncStatus.syncing => ('⟳', 'Syncing…', AppColors.primary),
      SyncStatus.offline => ('⚡', 'Offline', AppColors.warning),
      SyncStatus.failed => ('●', 'Sync failed', AppColors.negative),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: Text(
          '${data.$1} ${data.$2}',
          style: AppTextStyles.syncBadge.copyWith(color: data.$3),
        ),
      ),
    );
  }
}
