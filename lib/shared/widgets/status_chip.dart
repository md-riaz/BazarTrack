import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    super.key,
    this.backgroundColor = AppColors.surface3,
    this.foregroundColor = AppColors.text3,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: padding,
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
