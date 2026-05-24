import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class FrequentItemsRow extends StatelessWidget {
  const FrequentItemsRow({
    required this.items,
    super.key,
    this.onTap,
  });

  final List<String> items;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 10),
                child: InkWell(
                  onTap: onTap == null ? null : () => onTap!(item),
                  borderRadius: BorderRadius.circular(20),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.positiveLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      child: Text(
                        '+ $item',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.positiveDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
