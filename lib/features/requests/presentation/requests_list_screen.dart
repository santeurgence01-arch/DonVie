import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_emergency/core/constants/app_constants.dart';
import 'package:health_emergency/core/theme/app_theme.dart';
import 'package:health_emergency/core/widgets/empty_state_view.dart';
import 'package:health_emergency/core/widgets/skeleton_loader.dart';
import 'package:health_emergency/features/requests/application/requests_providers.dart';
import 'package:health_emergency/features/requests/presentation/widgets/demande_card.dart';

class RequestsListScreen extends ConsumerWidget {
  const RequestsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.sizeOf(context).width < kMobileBreakpoint;
    final activeAsync = ref.watch(activeDemandesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/requests/new'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouvelle demande', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? AppSpacing.screenPaddingMobile : AppSpacing.screenPaddingWeb,
            vertical: AppSpacing.sectionGap,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Demandes en cours', style: Theme.of(context).textTheme.headlineSmall),
                  TextButton(
                    onPressed: () => context.push('/requests/history'),
                    child: const Text('Historique'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: activeAsync.when(
                  loading: () => const SkeletonList(),
                  error: (e, _) => Center(child: Text('Erreur : $e')),
                  data: (demandes) {
                    if (demandes.isEmpty) {
                      return EmptyStateView(
                        icon: Icons.campaign_outlined,
                        title: "Aucune demande n'a encore été créée",
                        actionLabel: 'Créer une demande',
                        onAction: () => context.push('/requests/new'),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: demandes.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => DemandeCard(demande: demandes[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
