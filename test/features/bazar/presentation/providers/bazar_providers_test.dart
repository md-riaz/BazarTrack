import 'package:bazar/core/mock/mock_seed.dart';
import 'package:bazar/features/bazar/presentation/providers/bazar_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('frequentItemsProvider exposes seeded frequent items', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(frequentItemsProvider), MockSeed.frequentItems);
  });
}
