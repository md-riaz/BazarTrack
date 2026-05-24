import 'package:flutter/material.dart';

class SearchResultItem {
  const SearchResultItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.chipLabel,
    required this.chipBackgroundColor,
    required this.chipTextColor,
    required this.icon,
  });

  final SearchResultType type;
  final String title;
  final String subtitle;
  final String chipLabel;
  final Color chipBackgroundColor;
  final Color chipTextColor;
  final IconData icon;
}

enum SearchResultType {
  bazar('বাজার'),
  item('আইটেম'),
  money('টাকা');

  const SearchResultType(this.label);

  final String label;
}

class QuickSearchFilter {
  const QuickSearchFilter({
    required this.label,
    required this.query,
    required this.icon,
  });

  final String label;
  final String query;
  final IconData icon;
}
