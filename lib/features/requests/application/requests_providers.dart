import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_emergency/core/providers/current_structure_provider.dart';
import 'package:health_emergency/features/requests/data/demande_model.dart';
import 'package:health_emergency/features/requests/data/demande_repository.dart';

final demandeRepositoryProvider = Provider<DemandeRepository>((ref) {
  return DemandeRepository(FirebaseFirestore.instance);
});

final activeDemandesProvider = StreamProvider<List<DemandeModel>>((ref) {
  final structureId = ref.watch(currentStructureIdProvider);
  if (structureId == null) return Stream.value(const []);
  return ref.watch(demandeRepositoryProvider).watchActive(structureId);
});

final demandesHistoryProvider = StreamProvider<List<DemandeModel>>((ref) {
  final structureId = ref.watch(currentStructureIdProvider);
  if (structureId == null) return Stream.value(const []);
  return ref.watch(demandeRepositoryProvider).watchHistory(structureId);
});

final demandeDetailProvider = StreamProvider.family<DemandeModel?, String>((
  ref,
  id,
) {
  return ref.watch(demandeRepositoryProvider).watchDemande(id);
});

final reponsesProvider = StreamProvider.family<List<ReponseModel>, String>((
  ref,
  demandeId,
) {
  return ref.watch(demandeRepositoryProvider).watchReponses(demandeId);
});

final recentReponsesProvider = StreamProvider<List<ReponseModel>>((ref) {
  final structureId = ref.watch(currentStructureIdProvider);
  if (structureId == null) return Stream.value(const []);
  return ref.watch(demandeRepositoryProvider).watchRecentReponses(structureId);
});
