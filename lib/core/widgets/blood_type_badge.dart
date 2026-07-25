import 'package:flutter/material.dart';
import 'package:health_emergency/core/theme/app_theme.dart';

/// Badge pilule en lecture seule affichant un groupe sanguin
/// (fond `#F9DEDC`, texte `#B3261E` bold) — §3.3.
class BloodTypeBadge extends StatelessWidget {
  const BloodTypeBadge({super.key, required this.label, this.small = false});

  final String label;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: small ? 11 : 13,
        ),
      ),
    );
  }
}
