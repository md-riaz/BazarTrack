import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';

class ContentSkeleton extends StatelessWidget {
  const ContentSkeleton({super.key, this.rows = 4});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rows,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => Shimmer.fromColors(
        baseColor: AppColors.surface3,
        highlightColor: Colors.white,
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.surface3,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
