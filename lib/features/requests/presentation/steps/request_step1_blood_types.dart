import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_emergency/core/constants/app_constants.dart';
import 'package:health_emergency/core/theme/app_theme.dart';
import 'package:health_emergency/core/widgets/blood_type_chip.dart';
import 'package:health_emergency/features/requests/application/request_wizard_providers.dart';

class RequestStep1BloodTypes extends ConsumerWidget {
  const RequestStep1BloodTypes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(requestWizardControllerProvider);
    final controller = ref.read(requestWizardControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quel groupe sanguin recherchez-vous ?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width < kMobileBreakpoint ? 2 : 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: [
            for (final bt in kBloodTypes)
              BloodTypeChip(
                label: bt.label,
                selected: state.groupesSanguins.contains(bt.value),
                onTap: () => controller.toggleBloodType(bt.value),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: Row(
            children: [
              const Icon(Icons.insights_rounded, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyLarge,
                    children: [
                      const TextSpan(text: 'Basé sur vos critères, environ '),
                      TextSpan(
                        text: '${state.matchingCount} donneur${state.matchingCount > 1 ? 's' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' correspondent dans votre base.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
