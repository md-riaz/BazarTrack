import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class BazarAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BazarAppBar({
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: subtitle == null ? 64 : 72,
      backgroundColor: AppColors.primary,
      leading: leading,
      titleSpacing: leading == null ? 16 : 0,
      actionsPadding: const EdgeInsets.only(right: 8),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (subtitle != null)
            Text(subtitle!, style: AppTextStyles.appBarSubtitle),
          Text(title, style: AppTextStyles.appBarTitle),
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 64 : 72);
}
