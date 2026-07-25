import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_emergency/core/constants/app_constants.dart';
import 'package:health_emergency/features/dashboard/data/activity_event.dart';
import 'package:health_emergency/features/donors/application/donor_providers.dart';
import 'package:health_emergency/features/requests/application/requests_providers.dart';
import 'package:health_emergency/features/stock/application/stock_providers.dart';

/// Fusionne 4 flux Firestore (donneurs, demandes, réponses, mouvements de
/// stock) en une seule liste d'événements triée par date décroissante —
/// §4.3, point 5. Reste en "loading" tant qu'aucun des 4 flux n'a encore
/// livré de première valeur ; ensuite affiche ce qui est disponible.
final recentActivityProvider = Provider<AsyncValue<List<ActivityEvent>>>((
  ref,
) {
  final donorsAsync = ref.watch(donorsListProvider);
  final demandesAsync = ref.watch(demandesHistoryProvider);
  final reponsesAsync = ref.watch(recentReponsesProvider);
  final mouvementsAsync = ref.watch(stockHistoryProvider(null));

  final noneHaveValue =
      !donorsAsync.hasValue &&
      !demandesAsync.hasValue &&
      !reponsesAsync.hasValue &&
      !mouvementsAsync.hasValue;
  final anyLoading =
      donorsAsync.isLoading ||
      demandesAsync.isLoading ||
      reponsesAsync.isLoading ||
      mouvementsAsync.isLoading;
  if (anyLoading && noneHaveValue) {
    return const AsyncValue.loading();
  }

  for (final async in [donorsAsync, demandesAsync, reponsesAsync, mouvementsAsync]) {
    if (async.hasError && !async.hasValue) {
      return AsyncValue.error(async.error!, async.stackTrace!);
    }
  }

  final events = <ActivityEvent>[
    for (final d in donorsAsync.value ?? const [])
      if (d.createdAt != null)
        ActivityEvent(
          type: ActivityType.nouveauDonneur,
          description: '${d.nomComplet} a été enregistré comme donneur.',
          timestamp: d.createdAt!,
        ),
    for (final d in demandesAsync.value ?? const [])
      if (d.createdAt != null)
        ActivityEvent(
          type: ActivityType.nouvelleDemande,
          description:
              'Nouvelle demande créée (${d.groupesSanguins.join(", ")}).',
          timestamp: d.createdAt!,
        ),
    for (final r in reponsesAsync.value ?? const [])
      if (r.respondedAt != null)
        ActivityEvent(
          type: ActivityType.reponseDonneur,
          description: r.statut == ReponseStatut.confirme
              ? '${r.donneurNom} a confirmé sa disponibilité.'
              : '${r.donneurNom} a décliné la demande.',
          timestamp: r.respondedAt!,
        ),
    for (final m in mouvementsAsync.value ?? const [])
      if (m.date != null)
        ActivityEvent(
          type: ActivityType.mouvementStock,
          description: m.type == MouvementType.entree
              ? 'Stock ${m.groupeSanguin} : +${m.quantite} poche(s) — ${m.motif}.'
              : 'Stock ${m.groupeSanguin} : -${m.quantite} poche(s) — ${m.motif}.',
          timestamp: m.date!,
        ),
  ];

  events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return AsyncValue.data(events.take(10).toList());
});
