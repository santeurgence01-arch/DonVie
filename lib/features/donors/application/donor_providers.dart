import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_emergency/core/providers/current_structure_provider.dart';
import 'package:health_emergency/features/donors/data/donor_model.dart';
import 'package:health_emergency/features/donors/data/donor_repository.dart';
import 'package:health_emergency/features/stock/data/stock_model.dart';

final donorRepositoryProvider = Provider<DonorRepository>((ref) {
  return DonorRepository(FirebaseFirestore.instance);
});

final donorsListProvider = StreamProvider<List<DonorModel>>((ref) {
  final structureId = ref.watch(currentStructureIdProvider);
  if (structureId == null) return Stream.value(const []);
  return ref.watch(donorRepositoryProvider).watchDonors(structureId);
});

final donorDetailProvider = StreamProvider.family<DonorModel?, String>((
  ref,
  id,
) {
  return ref.watch(donorRepositoryProvider).watchDonor(id);
});

final donorHistoryProvider = StreamProvider.family<List<MouvementStock>, String>((
  ref,
  id,
) {
  return ref.watch(donorRepositoryProvider).watchDonorHistory(id);
});
