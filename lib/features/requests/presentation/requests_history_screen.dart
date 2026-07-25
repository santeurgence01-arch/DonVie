import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_emergency/core/constants/app_constants.dart';
import 'package:health_emergency/core/widgets/empty_state_view.dart';
import 'package:health_emergency/core/widgets/skeleton_loader.dart';
import 'package:health_emergency/features/requests/application/requests_providers.dart';
import 'package:health_emergency/features/requests/presentation/widgets/demande_card.dart';

enum _Periode { sept, trente, tout }

enum _StatutFiltre { toutes, cloturees, enCours }

class RequestsHistoryScreen extends ConsumerStatefulWidget {
  const RequestsHistoryScreen({super.key});

  @override
  ConsumerState<RequestsHistoryScreen> createState() => _RequestsHistoryScreenState();
}

class _RequestsHistoryScreenState extends ConsumerState<RequestsHistoryScreen> {
  _Periode _periode = _Periode.tout;
  _StatutFiltre _statut = _StatutFiltre.toutes;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(demandesHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Historique des demandes')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ChoiceChip(
                      label: const Text('7 derniers jours'),
                      selected: _periode == _Periode.sept,
                      onSelected: (_) => setState(() => _periode = _Periode.sept),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('30 jours'),
                      selected: _periode == _Periode.trente,
                      onSelected: (_) => setState(() => _periode = _Periode.trente),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Tout'),
                      selected: _periode == _Periode.tout,
                      onSelected: (_) => setState(() => _periode = _Periode.tout),
                    ),
                    const SizedBox(width: 20),
                    ChoiceChip(
                      label: const Text('Toutes'),
                      selected: _statut == _StatutFiltre.toutes,
                      onSelected: (_) => setState(() => _statut = _StatutFiltre.toutes),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Clôturées'),
                      selected: _statut == _StatutFiltre.cloturees,
                      onSelected: (_) => setState(() => _statut = _StatutFiltre.cloturees),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('En cours'),
                      selected: _statut == _StatutFiltre.enCours,
                      onSelected: (_) => setState(() => _statut = _StatutFiltre.enCours),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: historyAsync.when(
                  loading: () => const SkeletonList(),
                  error: (e, _) => Center(child: Text('Erreur : $e')),
                  data: (all) {
                    final now = DateTime.now();
                    final filtered = all.where((d) {
                      if (d.createdAt != null) {
                        final age = now.difference(d.createdAt!);
                        if (_periode == _Periode.sept && age.inDays > 7) return false;
                        if (_periode == _Periode.trente && age.inDays > 30) return false;
                      }
                      if (_statut == _StatutFiltre.cloturees &&
                          d.statut != DemandeStatut.cloturee) {
                        return false;
                      }
                      if (_statut == _StatutFiltre.enCours && d.statut != DemandeStatut.active) {
                        return false;
                      }
                      return true;
                    }).toList();

                    if (filtered.isEmpty) {
                      return EmptyStateView(
                        icon: Icons.history_rounded,
                        title: "Aucune demande n'a encore été créée",
                        actionLabel: 'Créer une demande',
                        onAction: () => context.push('/requests/new'),
                      );
                    }

                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => DemandeCard(demande: filtered[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
