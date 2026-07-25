import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_emergency/core/constants/app_constants.dart';
import 'package:health_emergency/core/theme/app_theme.dart';
import 'package:health_emergency/core/widgets/blood_type_chip.dart';
import 'package:health_emergency/features/onboarding/application/onboarding_providers.dart';

class Step3BloodTypes extends ConsumerStatefulWidget {
  const Step3BloodTypes({super.key});

  @override
  ConsumerState<Step3BloodTypes> createState() => _Step3BloodTypesState();
}

class _Step3BloodTypesState extends ConsumerState<Step3BloodTypes> {
  final _criteresController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _criteresController.text = ref.read(onboardingControllerProvider).criteresAdditionnels;
  }

  @override
  void dispose() {
    _criteresController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final isMobile = MediaQuery.sizeOf(context).width < kMobileBreakpoint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quels groupes sanguins souhaitez-vous gérer ?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.fieldGap),
        GridView.count(
          crossAxisCount: isMobile ? 2 : 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.6,
          children: [
            for (final bloodType in kBloodTypes)
              Center(
                child: BloodTypeChip(
                  label: bloodType.label,
                  selected: state.groupesSanguins.contains(bloodType.value),
                  onTap: () => controller.toggleBloodType(bloodType.value),
                ),
              ),
          ],
        ),
        if (state.showStep3Errors && state.groupesSanguins.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Sélectionnez au moins un groupe sanguin.',
              style: TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
        const SizedBox(height: AppSpacing.sectionGap),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Critères additionnels'),
          childrenPadding: const EdgeInsets.only(bottom: 16),
          children: [
            TextField(
              controller: _criteresController,
              maxLines: 3,
              onChanged: controller.setCriteres,
              decoration: const InputDecoration(
                labelText: 'Volume minimal requis, restrictions spécifiques...',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
