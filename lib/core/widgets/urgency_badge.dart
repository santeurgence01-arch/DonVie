import 'package:flutter/material.dart';
import 'package:health_emergency/core/constants/app_constants.dart';
import 'package:health_emergency/core/theme/app_theme.dart';

class UrgencyBadge extends StatelessWidget {
  const UrgencyBadge({super.key, required this.level, this.large = false});

  final UrgencyLevel level;
  final bool large;

  (Color bg, Color fg, IconData icon) get _style => switch (level) {
    UrgencyLevel.normal => (
      AppColors.successBg,
      AppColors.success,
      Icons.water_drop_outlined,
    ),
    UrgencyLevel.urgent => (
      AppColors.alertBg,
      AppColors.alertText,
      Icons.schedule_rounded,
    ),
    UrgencyLevel.critique => (
      AppColors.dangerBg,
      AppColors.danger,
      Icons.warning_rounded,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = _style;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 12,
        vertical: large ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: large ? 18 : 14, color: fg),
          const SizedBox(width: 6),
          Text(
            level.label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: large ? 15 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
