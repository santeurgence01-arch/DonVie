import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_emergency/core/constants/app_constants.dart';
import 'package:health_emergency/core/theme/app_theme.dart';
import 'package:health_emergency/core/widgets/primary_button.dart';
import 'package:health_emergency/core/widgets/step_header.dart';
import 'package:health_emergency/features/onboarding/application/onboarding_providers.dart';
import 'package:health_emergency/features/onboarding/presentation/steps/step1_identity.dart';
import 'package:health_emergency/features/onboarding/presentation/steps/step2_documents.dart';
import 'package:health_emergency/features/onboarding/presentation/steps/step3_blood_types.dart';
import 'package:health_emergency/features/onboarding/presentation/widgets/summary_modal.dart';

const _stepTitles = [
  'Identité de la structure',
  'Documents légaux',
  'Groupes sanguins gérés',
];

/// Coquille du wizard de configuration initiale (§4.2). Non fermable :
/// aucun bouton retour vers le dashboard tant que la configuration n'est
/// pas terminée.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final isMobile = MediaQuery.sizeOf(context).width < kMobileBreakpoint;
    final horizontalPadding = isMobile
        ? AppSpacing.screenPaddingMobile
        : AppSpacing.screenPaddingWeb;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.sectionGap,
                  horizontalPadding,
                  0,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: StepHeader(
                      currentStep: state.currentStep,
                      totalSteps: 3,
                      stepTitle: _stepTitles[state.currentStep - 1],
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
                            child: FadeTransition(
                              opacity: animation,
                              child: child,
                            ),
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
                          1 => const Step1Identity(),
                          2 => const Step2Documents(),
                          _ => const Step3BloodTypes(),
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const _BottomActionBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomActionBar extends ConsumerWidget {
  const _BottomActionBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final isMobile = MediaQuery.sizeOf(context).width < kMobileBreakpoint;
    final isLastStep = state.currentStep == 3;

    final currentStepValid = switch (state.currentStep) {
      1 => state.step1Valid,
      2 => state.step2Valid,
      _ => state.step3Valid,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile
            ? AppSpacing.screenPaddingMobile
            : AppSpacing.screenPaddingWeb,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (state.currentStep > 1)
                    TextButton(
                      onPressed: controller.previousStep,
                      child: const Text('Précédent'),
                    )
                  else
                    const SizedBox(width: 0),
                  const Spacer(),
                  SizedBox(
                    width: isMobile ? 160 : 220,
                    child: PrimaryButton(
                      label: isLastStep
                          ? 'Terminer la configuration'
                          : 'Suivant',
                      visuallyDisabled: !currentStepValid,
                      onPressed: () {
                        if (isLastStep) {
                          if (controller.attemptFinish()) {
                            showSummaryModal(context, ref);
                          }
                        } else {
                          controller.nextStep();
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (!currentStepValid &&
                  ((state.currentStep == 1 && state.showStep1Errors) ||
                      (state.currentStep == 2 && state.showStep2Errors) ||
                      (state.currentStep == 3 && state.showStep3Errors)))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _helpMessage(state.currentStep),
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _helpMessage(int step) {
    return switch (step) {
      1 => 'Renseignez le nom, le type et la localisation de la structure.',
      2 => 'Ajoutez au moins un document.',
      _ => 'Sélectionnez au moins un groupe sanguin.',
    };
  }
}
