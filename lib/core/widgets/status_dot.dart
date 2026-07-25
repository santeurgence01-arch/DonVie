import 'package:flutter/material.dart';
import 'package:health_emergency/core/theme/app_theme.dart';

/// Petit point de statut (vert = actif, gris = inactif) — §4.4.1.
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.active, this.size = 10});

  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.success : AppColors.textDisabled,
        border: Border.all(color: AppColors.surface, width: 1.5),
      ),
    );
  }
}
