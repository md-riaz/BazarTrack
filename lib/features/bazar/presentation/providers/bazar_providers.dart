import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../bootstrap.dart';
import '../../../../core/mock/mock_seed.dart';
import '../../../../core/sync/sync_providers.dart';
import '../../../../shared/models/app_enums.dart';
import '../../data/datasources/bazar_local_data_source.dart';
import '../../data/datasources/mock_bazar_remote_data_source.dart';
import '../../data/repositories/bazar_repository_impl.dart';
import '../../domain/entities/bazar_entities.dart';
import '../../domain/repositories/bazar_repository.dart';
import '../../domain/services/auto_parse_service.dart';

final bazarLocalDataSourceProvider = Provider<BazarLocalDataSource>((ref) {
  return BazarLocalDataSource(ref.watch(appDatabaseProvider));
});

final bazarRemoteDataSourceProvider = Provider<MockBazarRemoteDataSource>((
  ref,
) {
  return MockBazarRemoteDataSource();
});

final bazarRepositoryProvider = Provider<BazarRepository>((ref) {
  return BazarRepositoryImpl(
    localDataSource: ref.watch(bazarLocalDataSourceProvider),
    remoteDataSource: ref.watch(bazarRemoteDataSourceProvider),
    syncEnqueueService: ref.watch(syncEnqueueServiceProvider),
  );
});

final selectedBazarStatusProvider = StateProvider<BazarStatus?>((ref) => null);

final bazarsProvider = StreamProvider<List<Bazar>>((ref) {
  final status = ref.watch(selectedBazarStatusProvider);
  return ref.watch(bazarRepositoryProvider).watchBazars(status: status);
});

final bazarProvider = StreamProvider.family<Bazar?, String>((ref, bazarId) {
  return ref.watch(bazarRepositoryProvider).watchBazar(bazarId);
});

final bazarItemsProvider = StreamProvider.family<List<BazarItem>, String>((
  ref,
  bazarId,
) {
  return ref.watch(bazarRepositoryProvider).watchBazarItems(bazarId);
});

final bazarActivityProvider =
    StreamProvider.family<List<ActivityEvent>, String>((ref, bazarId) {
      return ref.watch(bazarRepositoryProvider).watchActivity(bazarId);
    });

final bazarSummaryProvider = FutureProvider.family<BazarSummary, String>((
  ref,
  bazarId,
) {
  return ref.watch(bazarRepositoryProvider).getSummary(bazarId);
});

final frequentItemsProvider = Provider<List<String>>((ref) {
  return MockSeed.frequentItems;
});

final autoParseServiceProvider = Provider<AutoParseService>((ref) {
  return const AutoParseService();
});

class BazarActionController extends StateNotifier<AsyncValue<void>> {
  BazarActionController(this._repository) : super(const AsyncData(null));

  final BazarRepository _repository;

  Future<Bazar?> createBazar(CreateBazarInput input) async {
    state = const AsyncLoading();
    try {
      final bazar = await _repository.createBazar(input);
      state = const AsyncData(null);
      return bazar;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<BazarItem?> addItem({
    required String bazarId,
    required CreateBazarItemInput item,
    String? userId,
  }) async {
    state = const AsyncLoading();
    try {
      final created = await _repository.addItem(
        bazarId: bazarId,
        item: item,
        userId: userId,
      );
      state = const AsyncData(null);
      return created;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  Future<void> updateItem({
    required String itemId,
    double? quantity,
    String? unit,
    double? price,
    String? note,
    ItemStatus? status,
    String? userId,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.updateItem(
        itemId: itemId,
        quantity: quantity,
        unit: unit,
        price: price,
        note: note,
        status: status,
        userId: userId,
      );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> closeBazar({required String bazarId, String? userId}) async {
    state = const AsyncLoading();
    try {
      await _repository.closeBazar(bazarId: bazarId, userId: userId);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}

final bazarActionControllerProvider =
    StateNotifierProvider<BazarActionController, AsyncValue<void>>((ref) {
      return BazarActionController(ref.watch(bazarRepositoryProvider));
    });
