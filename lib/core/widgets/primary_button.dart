import 'package:flutter/material.dart';
import 'package:health_emergency/core/theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.visuallyDisabled = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  /// Le bouton reste cliquable (utile pour afficher un message d'aide au
  /// clic sur un formulaire invalide) mais prend l'apparence "désactivé".
  final bool visuallyDisabled;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Text(label);

    if (!visuallyDisabled) {
      return ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.border,
        foregroundColor: AppColors.textDisabled,
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.textDisabled,
      ),
      child: child,
    );
  }
}
