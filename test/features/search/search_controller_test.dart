import 'package:bazar/features/search/data/datasources/mock_search_datasource.dart';
import 'package:bazar/features/search/data/repositories/search_repository_impl.dart';
import 'package:bazar/features/search/domain/entities/search_entities.dart';
import 'package:bazar/features/search/presentation/providers/search_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SearchController', () {
    SearchController buildController() {
      return SearchController(SearchRepositoryImpl(MockSearchDataSource()));
    }

    test('starts empty with bazar tab selected', () {
      final controller = buildController();

      expect(controller.state.query, '');
      expect(controller.state.type, SearchResultType.bazar);
      expect(controller.state.results.value, isEmpty);
      expect(controller.recentSearches, contains('CEO Personal'));
      expect(controller.quickFilters, hasLength(4));
    });

    test('searches current type when query changes', () async {
      final controller = buildController();

      await controller.updateQuery('CEO');

      expect(controller.state.query, 'CEO');
      expect(
        controller.state.results,
        isA<AsyncData<List<SearchResultItem>>>(),
      );
      expect(controller.state.results.value, hasLength(2));
      expect(
        controller.state.results.value!.first.type,
        SearchResultType.bazar,
      );
    });

    test('updates type and reruns active query', () async {
      final controller = buildController();

      await controller.updateQuery('দুধ');
      await controller.updateType(SearchResultType.item);

      expect(controller.state.type, SearchResultType.item);
      expect(controller.state.results.value, hasLength(2));
      expect(controller.state.results.value!.first.type, SearchResultType.item);
    });

    test('clears query and results', () async {
      final controller = buildController();

      await controller.updateQuery('Rahim');
      await controller.clear();

      expect(controller.state.query, '');
      expect(controller.state.results.value, isEmpty);
    });
  });
}
