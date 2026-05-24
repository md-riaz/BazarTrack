import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class BottomSheetHandle extends StatelessWidget {
  const BottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 48,
        height: 5,
        margin: const EdgeInsets.only(top: 10, bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.border2,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
