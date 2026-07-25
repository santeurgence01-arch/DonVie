import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_emergency/core/constants/app_constants.dart';
import 'package:health_emergency/core/theme/app_theme.dart';
import 'package:health_emergency/core/widgets/primary_button.dart';
import 'package:health_emergency/core/widgets/step_header.dart';
import 'package:health_emergency/features/requests/application/request_wizard_providers.dart';
import 'package:health_emergency/features/requests/presentation/steps/request_step1_blood_types.dart';
import 'package:health_emergency/features/requests/presentation/steps/request_step2_urgency.dart';
import 'package:health_emergency/features/requests/presentation/steps/request_step3_zone.dart';
import 'package:health_emergency/features/requests/presentation/steps/request_step4_recap.dart';

const _stepTitles = [
  'Groupe sanguin recherché',
  "Niveau d'urgence",
  'Zone géographique',
  'Récapitulatif et diffusion',
];

/// Wizard 4 étapes de création de demande — §4.6. Abandonnable via le "X"
/// (contrairement à l'onboarding, non bloquant).
class RequestWizardScreen extends ConsumerWidget {
  const RequestWizardScreen({super.key});

  Future<void> _confirmAbandon(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandonner la création de cette demande ?'),
        content: const Text('Les informations saisies seront perdues.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuer la création'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Abandonner'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(requestWizardControllerProvider);
    final isMobile = MediaQuery.sizeOf(context).width < kMobileBreakpoint;
    final horizontalPadding =
        isMobile ? AppSpacing.screenPaddingMobile : AppSpacing.screenPaddingWeb;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Row(
                    children: [
                      Expanded(
                        child: StepHeader(
                          currentStep: state.currentStep,
                          totalSteps: 4,
                          stepTitle: _stepTitles[state.currentStep - 1],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _confirmAbandon(context),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Abandonner',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    transitionBuilder: (child, animation) {
                      final offsetAnimation = Tween<Offset>(
                        begin: const Offset(0.08, 0),
                        end: Offset.zero,
                      ).animate(animation);
                      return ClipRect(
                        child: SlideTransition(
                          position: offsetAnimation,
                          child: FadeTransition(opacity: animation, child: child),
                        ),
                      );
                    },
                    child: SingleChildScrollView(
                      key: ValueKey(state.currentStep),
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: AppSpacing.sectionGap,
                      ),
                      child: switch (state.currentStep) {
                        1 => const RequestStep1BloodTypes(),
                        2 => const RequestStep2Urgency(),
                        3 => const RequestStep3Zone(),
                        _ => const RequestStep4Recap(),
                      },
                    ),
                  ),
                ),
              ),
            ),
            if (state.currentStep < 4) const _BottomActionBar(),
          ],
        ),
      ),
    );
  }
}

class _BottomActionBar extends ConsumerWidget {
  const _BottomActionBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(requestWizardControllerProvider);
    final controller = ref.read(requestWizardControllerProvider.notifier);
    final isMobile = MediaQuery.sizeOf(context).width < kMobileBreakpoint;

    final currentStepValid = switch (state.currentStep) {
      1 => state.step1Valid,
      2 => state.step2Valid,
      _ => state.step3Valid,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.screenPaddingMobile : AppSpacing.screenPaddingWeb,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Row(
            children: [
              if (state.currentStep > 1)
                TextButton(onPressed: controller.previousStep, child: const Text('Précédent'))
              else
                const SizedBox(width: 0),
              const Spacer(),
              SizedBox(
                width: isMobile ? 120 : 160,
                child: PrimaryButton(
                  label: 'Suivant',
                  visuallyDisabled: !currentStepValid,
                  onPressed: currentStepValid ? controller.nextStep : () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
