import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_emergency/core/constants/app_constants.dart';
import 'package:health_emergency/core/theme/app_theme.dart';
import 'package:health_emergency/core/widgets/blood_type_badge.dart';
import 'package:health_emergency/core/widgets/primary_button.dart';
import 'package:health_emergency/core/widgets/urgency_badge.dart';
import 'package:health_emergency/features/requests/application/request_wizard_providers.dart';

class RequestStep4Recap extends ConsumerWidget {
  const RequestStep4Recap({super.key});

  Future<void> _diffuse(BuildContext context, WidgetRef ref) async {
    final state = ref.read(requestWizardControllerProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la diffusion'),
        content: Text(
          'Cette action est immédiate et notifiera ${state.radiusMatchingCount} donneur${state.radiusMatchingCount > 1 ? 's' : ''}. Confirmez-vous ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer la diffusion'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final demande = await ref.read(requestWizardControllerProvider.notifier).submit();
    if (!context.mounted) return;
    if (demande != null) {
      HapticFeedback.mediumImpact();
      context.pushReplacement('/requests/${demande.id}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de la diffusion, veuillez réessayer.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(requestWizardControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Vérifiez votre demande avant de la diffuser',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: kCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Groupes sanguins recherchés', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final bt in state.groupesSanguins) BloodTypeBadge(label: bt),
                ],
              ),
              const SizedBox(height: 16),
              Text("Niveau d'urgence", style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              UrgencyBadge(level: state.niveauUrgence ?? UrgencyLevel.normal),
              const SizedBox(height: 16),
              Text('Rayon de recherche', style: Theme.of(context).textTheme.labelLarge),
              Text('${state.rayonKm.round()} km', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              Text('Donneurs qui recevront la notification', style: Theme.of(context).textTheme.labelLarge),
              Text(
                '${state.radiusMatchingCount}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
        if (state.niveauUrgence == UrgencyLevel.critique) ...[
          const SizedBox(height: AppSpacing.fieldGap),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.dangerBg,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.danger, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Un appel automatique sera déclenché en plus de la notification push pour tous les donneurs compatibles.',
                    style: const TextStyle(color: AppColors.danger, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sectionGap),
        PrimaryButton(
          label: 'Diffuser la demande maintenant',
          isLoading: state.isSubmitting,
          onPressed: () => _diffuse(context, ref),
        ),
      ],
    );
  }
}
