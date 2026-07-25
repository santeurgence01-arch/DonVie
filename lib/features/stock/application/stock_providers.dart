import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_emergency/core/providers/current_structure_provider.dart';
import 'package:health_emergency/features/stock/data/stock_model.dart';
import 'package:health_emergency/features/stock/data/stock_repository.dart';

final stockRepositoryProvider = Provider<StockRepository>((ref) {
  return StockRepository(FirebaseFirestore.instance);
});

final stockListProvider = StreamProvider<List<StockItem>>((ref) {
  final structureId = ref.watch(currentStructureIdProvider);
  if (structureId == null) return Stream.value(const []);
  return ref.watch(stockRepositoryProvider).watchStock(structureId);
});

final stockAlertCountProvider = Provider<int>((ref) {
  final stock = ref.watch(stockListProvider).value ?? const [];
  return stock.where((s) => s.niveau == StockLevel.critique).length;
});

final stockHistoryProvider =
    StreamProvider.family<List<MouvementStock>, String?>((ref, groupeSanguin) {
      final structureId = ref.watch(currentStructureIdProvider);
      if (structureId == null) return Stream.value(const []);
      return ref
          .watch(stockRepositoryProvider)
          .watchHistory(structureId, groupeSanguin: groupeSanguin);
    });
