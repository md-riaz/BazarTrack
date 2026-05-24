import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTextStyles.sectionTitle)),
          if (action != null)
            InkWell(
              onTap: onAction,
              child: Text(action!, style: AppTextStyles.sectionAction),
            ),
        ],
      ),
    );
  }
}
