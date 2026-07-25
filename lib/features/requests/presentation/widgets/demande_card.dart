import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_emergency/core/constants/app_constants.dart';
import 'package:health_emergency/core/theme/app_theme.dart';
import 'package:health_emergency/core/widgets/blood_type_badge.dart';
import 'package:health_emergency/core/widgets/urgency_badge.dart';
import 'package:health_emergency/features/requests/application/requests_providers.dart';
import 'package:health_emergency/features/requests/data/demande_model.dart';
import 'package:intl/intl.dart';

/// Carte résumant une demande — utilisée pour la liste "en cours" (§4.6
/// accès) et pour l'historique (§4.8).
class DemandeCard extends ConsumerWidget {
  const DemandeCard({super.key, required this.demande});

  final DemandeModel demande;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reponsesAsync = ref.watch(reponsesProvider(demande.id));
    final reponses = reponsesAsync.value ?? const [];
    final confirmes = reponses.where((r) => r.statut == ReponseStatut.confirme).length;
    final total = reponses.isNotEmpty ? reponses.length : demande.nombreDonneursEstime;
    final ratio = total == 0 ? 0.0 : confirmes / total;
    final isCloturee = demande.statut == DemandeStatut.cloturee;

    return InkWell(
      onTap: () => context.push('/requests/${demande.id}'),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: kCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    demande.createdAt != null
                        ? DateFormat('dd/MM/yyyy à HH:mm').format(demande.createdAt!)
                        : '—',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Text(
                  isCloturee ? 'Clôturée' : 'En cours',
                  style: TextStyle(
                    color: isCloturee ? AppColors.textSecondary : AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final bt in demande.groupesSanguins) BloodTypeBadge(label: bt, small: true),
                UrgencyBadge(level: demande.niveauUrgence),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: AppColors.background,
                      valueColor: const AlwaysStoppedAnimation(AppColors.success),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('$confirmes/$total confirmés', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
