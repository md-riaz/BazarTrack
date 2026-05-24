import '../entities/search_entities.dart';

abstract class SearchRepository {
  Future<List<SearchResultItem>> search({
    required String query,
    required SearchResultType type,
  });

  List<String> recentSearches();
  List<QuickSearchFilter> quickFilters();
}
