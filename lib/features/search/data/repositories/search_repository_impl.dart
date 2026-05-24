import '../../domain/entities/search_entities.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/mock_search_datasource.dart';

class SearchRepositoryImpl implements SearchRepository {
  const SearchRepositoryImpl(this._dataSource);

  final SearchDataSource _dataSource;

  @override
  Future<List<SearchResultItem>> search({
    required String query,
    required SearchResultType type,
  }) {
    return _dataSource.search(query: query, type: type);
  }

  @override
  List<String> recentSearches() {
    return _dataSource.recentSearches();
  }

  @override
  List<QuickSearchFilter> quickFilters() {
    return _dataSource.quickFilters();
  }
}
