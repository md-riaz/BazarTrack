import 'package:bazar/core/router/app_router.dart';
import 'package:bazar/features/search/data/datasources/mock_search_datasource.dart';
import 'package:bazar/features/search/data/repositories/search_repository_impl.dart';
import 'package:bazar/features/search/domain/entities/search_entities.dart';
import 'package:bazar/features/search/presentation/providers/search_providers.dart';
import 'package:flutter/material.dart' hide SearchController;
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

    test('mock results expose target metadata for routing', () async {
      final controller = buildController();

      await controller.updateQuery('CEO');
      final bazar = controller.state.results.value!.first;

      await controller.updateType(SearchResultType.item);
      final item = controller.state.results.value!.first;

      await controller.updateType(SearchResultType.money);
      final money = controller.state.results.value!.first;

      expect(bazar.entityId, 'b1');
      expect(bazar.bazarId, 'b1');
      expect(bazar.walletId, 'w2');
      expect(item.entityId, 'i4');
      expect(item.bazarId, 'b1');
      expect(money.entityId, 'm2');
      expect(money.walletId, 'w2');
    });

    test('search routes use metadata instead of title text', () {
      final unknownTitleBazar = _result(
        type: SearchResultType.bazar,
        title: 'renamed bazar result',
        entityId: 'b2',
      );
      final unknownTitleItem = _result(
        type: SearchResultType.item,
        title: 'renamed item result',
        bazarId: 'b1',
      );
      final unknownTitleMoney = _result(
        type: SearchResultType.money,
        title: 'renamed money result',
        walletId: 'w1',
      );

      expect(
        routeForSearchResult(unknownTitleBazar),
        AppRoutes.bazarDetail('b2'),
      );
      expect(
        routeForSearchResult(unknownTitleItem),
        AppRoutes.bazarDetail('b1'),
      );
      expect(
        routeForSearchResult(unknownTitleMoney),
        AppRoutes.walletDetail('w1'),
      );
    });

    test(
      'search routes fall back to stable lists when metadata is missing',
      () {
        expect(
          routeForSearchResult(_result(type: SearchResultType.bazar)),
          AppRoutes.bazarList,
        );
        expect(
          routeForSearchResult(_result(type: SearchResultType.item)),
          AppRoutes.bazarList,
        );
        expect(
          routeForSearchResult(_result(type: SearchResultType.money)),
          AppRoutes.balance,
        );
      },
    );
  });
}

SearchResultItem _result({
  required SearchResultType type,
  String title = 'Search result',
  String? entityId,
  String? parentId,
  String? bazarId,
  String? walletId,
}) {
  return SearchResultItem(
    type: type,
    title: title,
    subtitle: 'subtitle',
    chipLabel: 'chip',
    chipBackgroundColor: Colors.white,
    chipTextColor: Colors.black,
    icon: Icons.search,
    entityId: entityId,
    parentId: parentId,
    bazarId: bazarId,
    walletId: walletId,
  );
}
