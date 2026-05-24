import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';

class GhostButton extends StatelessWidget {
  const GhostButton({
    required this.label,
    super.key,
    this.onPressed,
    this.foregroundColor,
    this.borderColor,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? foregroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: margin,
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          style: theme.outlinedButtonTheme.style?.copyWith(
            foregroundColor: WidgetStatePropertyAll(foregroundColor),
            side: WidgetStatePropertyAll(
              BorderSide(
                color: borderColor ?? theme.colorScheme.outline,
                width: 1.5,
              ),
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.ghostButton.copyWith(color: foregroundColor),
          ),
        ),
      ),
    );
  }
}
