import 'dart:typed_data';

import '../../../../shared/models/app_enums.dart';
import '../entities/bazar_entities.dart';

abstract class BazarRepository {
  Stream<List<Bazar>> watchBazars({BazarStatus? status});

  Stream<Bazar?> watchBazar(String bazarId);

  Stream<List<BazarItem>> watchBazarItems(String bazarId);

  Stream<List<ActivityEvent>> watchActivity(String bazarId);

  Future<List<Bazar>> refreshBazars();

  Future<Bazar> createBazar(CreateBazarInput input);

  Future<BazarItem> addItem({
    required String bazarId,
    required CreateBazarItemInput item,
    String? userId,
  });

  Future<BazarItem> updateItem({
    required String itemId,
    double? quantity,
    String? unit,
    double? price,
    String? note,
    String? receiptUrl,
    ItemStatus? status,
    String? userId,
  });

  Future<String> uploadReceipt({
    required String itemId,
    required Uint8List imageBytes,
  });

  Future<Bazar> closeBazar({required String bazarId, String? userId});

  Future<BazarSummary> getSummary(String bazarId);
}
