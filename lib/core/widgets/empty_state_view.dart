import 'package:flutter/material.dart';
import 'package:health_emergency/core/theme/app_theme.dart';
import 'package:health_emergency/core/widgets/primary_button.dart';

/// État vide générique — §5.
/// - [title]/[message]/[actionLabel] : cas "jamais de données" (avec icône).
/// - Sans [actionLabel] mais avec [onSecondaryAction] : cas "vide après
///   filtrage" (texte simple + bouton "Réinitialiser les filtres").
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final hasIllustration = actionLabel != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasIllustration) ...[
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 260,
                child: PrimaryButton(label: actionLabel!, onPressed: onAction),
              ),
            ],
            if (secondaryActionLabel != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(secondaryActionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
