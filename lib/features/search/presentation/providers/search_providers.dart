import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/mock_search_datasource.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/entities/search_entities.dart';
import '../../domain/repositories/search_repository.dart';

final searchDataSourceProvider = Provider<SearchDataSource>((ref) {
  return MockSearchDataSource();
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepositoryImpl(ref.watch(searchDataSourceProvider));
});

class SearchState {
  const SearchState({
    this.query = '',
    this.type = SearchResultType.bazar,
    this.results = const AsyncValue.data([]),
  });

  final String query;
  final SearchResultType type;
  final AsyncValue<List<SearchResultItem>> results;

  SearchState copyWith({
    String? query,
    SearchResultType? type,
    AsyncValue<List<SearchResultItem>>? results,
  }) {
    return SearchState(
      query: query ?? this.query,
      type: type ?? this.type,
      results: results ?? this.results,
    );
  }
}

class SearchController extends StateNotifier<SearchState> {
  SearchController(this._repository) : super(const SearchState());

  final SearchRepository _repository;

  List<String> get recentSearches => _repository.recentSearches();
  List<QuickSearchFilter> get quickFilters => _repository.quickFilters();

  Future<void> updateQuery(String query) async {
    state = state.copyWith(query: query);
    await _runSearch();
  }

  Future<void> updateType(SearchResultType type) async {
    state = state.copyWith(type: type);
    await _runSearch();
  }

  Future<void> clear() async {
    state = const SearchState();
  }

  Future<void> _runSearch() async {
    final query = state.query;
    if (query.trim().isEmpty) {
      state = state.copyWith(results: const AsyncValue.data([]));
      return;
    }

    state = state.copyWith(results: const AsyncValue.loading());
    final type = state.type;
    state = state.copyWith(
      results: await AsyncValue.guard(
        () => _repository.search(query: query, type: type),
      ),
    );
  }
}

final searchControllerProvider =
    StateNotifierProvider<SearchController, SearchState>((ref) {
      return SearchController(ref.watch(searchRepositoryProvider));
    });
