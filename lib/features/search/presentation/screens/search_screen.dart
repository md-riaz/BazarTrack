import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../domain/entities/search_entities.dart';
import '../providers/search_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.onResultTap});

  final ValueChanged<SearchResultItem>? onResultTap;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _setQuery(String query) async {
    _controller.text = query;
    _controller.selection = TextSelection.collapsed(offset: query.length);
    await ref.read(searchControllerProvider.notifier).updateQuery(query);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);
    final controller = ref.read(searchControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.surface2,
      appBar: const BazarAppBar(title: 'Search'),
      body: ListView(
        children: [
          _SearchBox(
            controller: _controller,
            onChanged: (query) =>
                ref.read(searchControllerProvider.notifier).updateQuery(query),
            onClear: () {
              _controller.clear();
              ref.read(searchControllerProvider.notifier).clear();
            },
          ),
          _SearchTypeTabs(
            selected: state.type,
            onChanged: (type) =>
                ref.read(searchControllerProvider.notifier).updateType(type),
          ),
          if (state.query.trim().isEmpty) ...[
            _SuggestionSection(
              title: 'সাম্প্রতিক সার্চ',
              chips: [
                for (final query in controller.recentSearches)
                  _SuggestionChip(
                    label: query,
                    icon: Icons.history,
                    onTap: () => _setQuery(query),
                  ),
              ],
            ),
            _SuggestionSection(
              title: 'Quick Filters',
              chips: [
                for (final filter in controller.quickFilters)
                  _SuggestionChip(
                    label: filter.label,
                    icon: filter.icon,
                    onTap: () => _setQuery(filter.query),
                  ),
              ],
            ),
          ] else
            _SearchResults(
              results: state.results,
              onResultTap: widget.onResultTap,
            ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'বাজার, আইটেম, ইউজার খুঁজুন...',
          hintStyle: AppTextStyles.body.copyWith(color: AppColors.text4),
          prefixIcon: const Icon(Icons.search, color: AppColors.text3),
          suffixIcon: IconButton(
            tooltip: 'সার্চ মুছুন',
            onPressed: onClear,
            icon: const Icon(Icons.close, color: AppColors.text4),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _SearchTypeTabs extends StatelessWidget {
  const _SearchTypeTabs({required this.selected, required this.onChanged});

  final SearchResultType selected;
  final ValueChanged<SearchResultType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface3,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final type in SearchResultType.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: type == selected,
                label: '${type.label} সার্চ ট্যাব',
                child: InkWell(
                  borderRadius: BorderRadius.circular(9),
                  onTap: () => onChanged(type),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: type == selected
                          ? AppColors.surface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Text(
                        type.label,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: type == selected
                              ? AppColors.primary
                              : AppColors.text3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SuggestionSection extends StatelessWidget {
  const _SuggestionSection({required this.title, required this.chips});

  final String title;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.sectionTitle),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 16, color: AppColors.primary),
      label: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryText),
      ),
      backgroundColor: AppColors.primaryLight,
      side: const BorderSide(color: AppColors.primaryBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.results, required this.onResultTap});

  final AsyncValue<List<SearchResultItem>> results;
  final ValueChanged<SearchResultItem>? onResultTap;

  @override
  Widget build(BuildContext context) {
    return results.when(
      data: (items) {
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'কোন ফলাফল পাওয়া যায়নি',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
          );
        }
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < items.length; index++)
                _ResultTile(
                  item: items[index],
                  showDivider: index < items.length - 1,
                  onTap: onResultTap == null
                      ? null
                      : () => onResultTap!(items[index]),
                ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(28),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'সার্চ করা যায়নি',
          style: AppTextStyles.body,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.item,
    required this.showDivider,
    this.onTap,
  });

  final SearchResultItem item;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(
                  bottom: BorderSide(color: AppColors.surface3, width: 0.5),
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface3,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(item.icon, size: 18, color: AppColors.text2),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTextStyles.bodyStrong.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.text3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _Chip(
              label: item.chipLabel,
              background: item.chipBackgroundColor,
              foreground: item.chipTextColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: foreground,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
