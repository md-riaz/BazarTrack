import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/search_entities.dart';

abstract class SearchDataSource {
  Future<List<SearchResultItem>> search({
    required String query,
    required SearchResultType type,
  });

  List<String> recentSearches();
  List<QuickSearchFilter> quickFilters();
}

class MockSearchDataSource implements SearchDataSource {
  static const Map<SearchResultType, List<SearchResultItem>> _results = {
    SearchResultType.bazar: [
      SearchResultItem(
        type: SearchResultType.bazar,
        title: 'CEO Personal বাজার',
        subtitle: 'Rahim · ২৩ মে · চলতেছে',
        chipLabel: 'চলতেছে',
        chipBackgroundColor: AppColors.warningLight,
        chipTextColor: AppColors.warningDark,
        icon: Icons.shopping_basket_outlined,
        entityId: 'b1',
        bazarId: 'b1',
        walletId: 'w2',
      ),
      SearchResultItem(
        type: SearchResultType.bazar,
        title: 'Office Lunch বাজার',
        subtitle: 'Karim · ২২ মে · শেষ',
        chipLabel: 'শেষ',
        chipBackgroundColor: AppColors.positiveLight,
        chipTextColor: AppColors.positiveDark,
        icon: Icons.shopping_basket_outlined,
        entityId: 'b2',
        bazarId: 'b2',
        walletId: 'w1',
      ),
    ],
    SearchResultType.item: [
      SearchResultItem(
        type: SearchResultType.item,
        title: 'ডিম ৩০টা',
        subtitle: 'CEO Personal বাজার · ২৩ মে · বাকি',
        chipLabel: 'বাকি',
        chipBackgroundColor: AppColors.warningLight,
        chipTextColor: AppColors.warningDark,
        icon: Icons.egg_alt_outlined,
        entityId: 'i4',
        parentId: 'b1',
        bazarId: 'b1',
        walletId: 'w2',
      ),
      SearchResultItem(
        type: SearchResultType.item,
        title: 'দুধ ২ প্যাকেট',
        subtitle: 'Office Lunch · ২২ মে · কেনা',
        chipLabel: 'কেনা',
        chipBackgroundColor: AppColors.positiveLight,
        chipTextColor: AppColors.positiveDark,
        icon: Icons.local_drink_outlined,
        entityId: 'i3',
        parentId: 'b1',
        bazarId: 'b1',
        walletId: 'w2',
      ),
    ],
    SearchResultType.money: [
      SearchResultItem(
        type: SearchResultType.money,
        title: '৳ ৫,০০০ নিলাম',
        subtitle: 'Rahim · CEO Personal · ২০ মে',
        chipLabel: 'নিলাম',
        chipBackgroundColor: AppColors.positiveLight,
        chipTextColor: AppColors.positiveDark,
        icon: Icons.payments_outlined,
        entityId: 'm2',
        bazarId: 'b1',
        walletId: 'w2',
      ),
      SearchResultItem(
        type: SearchResultType.money,
        title: '৳ ২৫০ ফেরত',
        subtitle: 'Rahim · Office · ১০ মে',
        chipLabel: 'ফেরত',
        chipBackgroundColor: AppColors.warningLight,
        chipTextColor: AppColors.warningDark,
        icon: Icons.keyboard_return_outlined,
        entityId: 'm4',
        walletId: 'w1',
      ),
    ],
  };

  @override
  Future<List<SearchResultItem>> search({
    required String query,
    required SearchResultType type,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (query.trim().isEmpty) {
      return const [];
    }
    return List<SearchResultItem>.unmodifiable(_results[type] ?? const []);
  }

  @override
  List<String> recentSearches() {
    return const ['CEO Personal', 'গরুর মাংস', 'Rahim', 'দুধ'];
  }

  @override
  List<QuickSearchFilter> quickFilters() {
    return const [
      QuickSearchFilter(
        label: 'চলছে',
        query: 'চলছে',
        icon: Icons.timer_outlined,
      ),
      QuickSearchFilter(
        label: 'আজকের',
        query: 'আজকের',
        icon: Icons.assignment_outlined,
      ),
      QuickSearchFilter(
        label: 'পাওয়া যায়নি',
        query: 'পাওয়া যায়নি',
        icon: Icons.cancel_outlined,
      ),
      QuickSearchFilter(
        label: 'নেগেটিভ',
        query: 'নেগেটিভ',
        icon: Icons.warning_amber_rounded,
      ),
    ];
  }
}
