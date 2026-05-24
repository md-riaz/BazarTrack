import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppDivider extends StatelessWidget {
  const AppDivider({super.key, this.height = 8});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(height: height, color: AppColors.surface2);
  }
}
