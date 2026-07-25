import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_emergency/core/constants/app_constants.dart';
import 'package:health_emergency/core/theme/app_theme.dart';
import 'package:health_emergency/features/requests/application/request_wizard_providers.dart';

class RequestStep2Urgency extends ConsumerWidget {
  const RequestStep2Urgency({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(requestWizardControllerProvider);
    final controller = ref.read(requestWizardControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Quel est le niveau d'urgence ?", style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.sectionGap),
        _UrgencyCard(
          level: UrgencyLevel.normal,
          icon: Icons.water_drop_outlined,
          bg: AppColors.successBg,
          color: AppColors.success,
          description: "Réapprovisionnement de la réserve, pas d'urgence médicale immédiate.",
          selected: state.niveauUrgence == UrgencyLevel.normal,
          onTap: () => controller.setUrgency(UrgencyLevel.normal),
        ),
        const SizedBox(height: 12),
        _UrgencyCard(
          level: UrgencyLevel.urgent,
          icon: Icons.schedule_rounded,
          bg: AppColors.alertBg,
          color: AppColors.alertText,
          description: 'Besoin à couvrir rapidement.',
          selected: state.niveauUrgence == UrgencyLevel.urgent,
          onTap: () => controller.setUrgency(UrgencyLevel.urgent),
        ),
        const SizedBox(height: 12),
        _UrgencyCard(
          level: UrgencyLevel.critique,
          icon: Icons.warning_rounded,
          bg: AppColors.dangerBg,
          color: AppColors.danger,
          description:
              'Besoin vital immédiat — déclenche un appel automatique à tous les donneurs compatibles.',
          selected: state.niveauUrgence == UrgencyLevel.critique,
          onTap: () => controller.setUrgency(UrgencyLevel.critique),
        ),
      ],
    );
  }
}

class _UrgencyCard extends StatelessWidget {
  const _UrgencyCard({
    required this.level,
    required this.icon,
    required this.bg,
    required this.color,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final UrgencyLevel level;
  final IconData icon;
  final Color bg;
  final Color color;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? bg : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: selected ? color : AppColors.border, width: selected ? 2 : 1),
          boxShadow: kCardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.label,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: selected ? color : null),
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: color),
          ],
        ),
      ),
    );
  }
}
