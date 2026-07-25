import 'package:flutter/material.dart';
import 'package:health_emergency/core/theme/app_theme.dart';

/// Stepper horizontal fixe : cercles numérotés reliés par une ligne.
/// Étape active = cercle plein rouge ; étapes complétées = coche blanche
/// sur fond rouge ; étapes futures = contour gris.
class StepHeader extends StatelessWidget {
  const StepHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepTitle,
  });

  final int currentStep;
  final int totalSteps;
  final String stepTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(totalSteps * 2 - 1, (i) {
            if (i.isOdd) {
              final segmentIndex = (i - 1) ~/ 2 + 1;
              final isPassed = segmentIndex < currentStep;
              return Expanded(
                child: Container(
                  height: 2,
                  color: isPassed ? AppColors.primary : AppColors.border,
                ),
              );
            }
            final stepNumber = i ~/ 2 + 1;
            final isCompleted = stepNumber < currentStep;
            final isActive = stepNumber == currentStep;
            return _StepCircle(
              number: stepNumber,
              isCompleted: isCompleted,
              isActive: isActive,
            );
          }),
        ),
        const SizedBox(height: 12),
        Text(
          'Étape $currentStep sur $totalSteps — $stepTitle',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.number,
    required this.isCompleted,
    required this.isActive,
  });

  final int number;
  final bool isCompleted;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final filled = isCompleted || isActive;
    return Semantics(
      label: 'Étape $number${isCompleted ? ' complétée' : ''}${isActive ? ' en cours' : ''}',
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? AppColors.primary : AppColors.surface,
          border: Border.all(
            color: filled ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: isCompleted
            ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
            : Text(
                '$number',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isActive ? Colors.white : AppColors.textDisabled,
                ),
              ),
      ),
    );
  }
}
