import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_emergency/core/constants/app_constants.dart';
import 'package:health_emergency/core/theme/app_theme.dart';
import 'package:health_emergency/core/widgets/primary_button.dart';
import 'package:health_emergency/features/onboarding/application/onboarding_providers.dart';

Future<void> showSummaryModal(BuildContext context, WidgetRef ref) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Récapitulatif',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const _SummaryModalContent();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _SummaryModalContent extends ConsumerWidget {
  const _SummaryModalContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final isMobile = MediaQuery.sizeOf(context).width < kMobileBreakpoint;

    final typeLabel = kStructureTypes
        .firstWhere((t) => t.value == state.structureType, orElse: () => kStructureTypes.first)
        .label;

    return PopScope(
      canPop: !state.isSubmitting,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 80,
          vertical: 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: state.isSubmitting
              ? const _SubmittingOverlay()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Vérifiez votre structure avant de confirmer',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),
                      _RecapSection(
                        title: 'Identité de la structure',
                        onEdit: () {
                          Navigator.of(context).pop();
                          controller.goToStep(1);
                        },
                        children: [
                          _RecapLine('Nom', state.nom),
                          _RecapLine('Type', typeLabel),
                          _RecapLine('Adresse', state.adresse.isEmpty ? '—' : state.adresse),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.fieldGap),
                      _RecapSection(
                        title: 'Documents légaux',
                        onEdit: () {
                          Navigator.of(context).pop();
                          controller.goToStep(2);
                        },
                        children: [
                          for (final doc in state.documents.where((d) => d.uploaded != null))
                            _RecapLine('Document', doc.fileName),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.fieldGap),
                      _RecapSection(
                        title: 'Groupes sanguins',
                        onEdit: () {
                          Navigator.of(context).pop();
                          controller.goToStep(3);
                        },
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final bt in state.groupesSanguins)
                                Chip(label: Text(bt)),
                            ],
                          ),
                          if (state.criteresAdditionnels.trim().isNotEmpty)
                            _RecapLine('Critères', state.criteresAdditionnels),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),
                      PrimaryButton(
                        label: 'Confirmer et créer ma structure',
                        onPressed: () async {
                          final success = await controller.submit();
                          if (success && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      if (state.submitError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Une erreur est survenue, veuillez réessayer.',
                          style: const TextStyle(color: AppColors.danger, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _SubmittingOverlay extends StatelessWidget {
  const _SubmittingOverlay();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Configuration de votre structure en cours...',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RecapSection extends StatelessWidget {
  const _RecapSection({
    required this.title,
    required this.onEdit,
    required this.children,
  });

  final String title;
  final VoidCallback onEdit;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: 'Modifier',
              onPressed: onEdit,
            ),
          ],
        ),
        ...children,
      ],
    );
  }
}

class _RecapLine extends StatelessWidget {
  const _RecapLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
