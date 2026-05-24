import 'package:bazar/features/comments/presentation/providers/comments_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('comments providers', () {
    test('loads prototype comments and clears draft state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final comments = container.read(bazarCommentsProvider);

      expect(comments, hasLength(4));
      expect(comments.first.user, 'CEO');
      expect(comments.first.isOwner, isTrue);
      expect(comments.last.message, contains('চিকেন ১.৫ কেজি'));
      expect(container.read(draftCommentProvider), '');

      container.read(draftCommentProvider.notifier).state = 'টেস্ট মন্তব্য';
      expect(container.read(draftCommentProvider), 'টেস্ট মন্তব্য');

      container.read(draftCommentProvider.notifier).state = '';
      expect(container.read(draftCommentProvider), '');
    });

    test('calculates price history summary values', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final history = container.read(priceHistoryProvider);

      expect(history.itemName, 'ডিম');
      expect(history.unit, 'টা');
      expect(history.entries, hasLength(6));
      expect(history.latestPrice, 210);
      expect(history.maxPrice, 210);
      expect(history.averagePerUnit, 6.53);
    });
  });
}
