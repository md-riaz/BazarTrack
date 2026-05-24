import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const String fontFamily = 'Noto Sans Bengali';
  static const List<String> fontFamilyFallback = <String>[
    'Noto Sans Bengali',
    'Hind Siliguri',
    'Noto Sans',
    'Roboto',
    'sans-serif',
  ];

  static const TextStyle appBarTitle = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: -0.3,
    height: 1.2,
  );

  static const TextStyle appBarSubtitle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: Color.fromRGBO(255, 255, 255, 0.75),
    letterSpacing: 0.5,
    height: 1.2,
  );

  static const TextStyle screenTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.text1,
    letterSpacing: -0.4,
    height: 1.2,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.text1,
    height: 1.3,
  );

  static const TextStyle sectionAction = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.text2,
    height: 1.45,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.text1,
    height: 1.35,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.text3,
    height: 1.35,
  );

  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.text3,
    letterSpacing: 0.44,
    height: 1.3,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.text4,
    letterSpacing: 0.6,
    height: 1.2,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.25,
  );

  static const TextStyle ghostButton = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.text3,
    height: 1.25,
  );

  static const TextStyle walletAmount = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: -0.5,
    height: 1.15,
  );

  static const TextStyle syncBadge = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
}
