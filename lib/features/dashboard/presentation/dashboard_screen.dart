import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_emergency/core/constants/app_constants.dart';
import 'package:health_emergency/core/theme/app_theme.dart';
import 'package:health_emergency/core/widgets/empty_state_view.dart';
import 'package:health_emergency/core/widgets/skeleton_loader.dart';
import 'package:health_emergency/features/dashboard/application/dashboard_providers.dart';
import 'package:health_emergency/features/dashboard/data/activity_event.dart';
import 'package:health_emergency/features/donors/application/donor_providers.dart';
import 'package:health_emergency/features/onboarding/application/onboarding_providers.dart';
import 'package:health_emergency/features/requests/application/requests_providers.dart';
import 'package:health_emergency/features/stock/application/stock_providers.dart';
import 'package:health_emergency/features/stock/data/stock_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.sizeOf(context).width < kMobileBreakpoint;
    final structure = ref.watch(structureDocProvider).value;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/requests/new'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nouvelle demande',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile
                ? AppSpacing.screenPaddingMobile
                : AppSpacing.screenPaddingWeb,
            vertical: AppSpacing.sectionGap,
          ).copyWith(bottom: 96),
          children: [
            _Header(structureName: structure?.nom ?? 'Votre structure'),
            const SizedBox(height: AppSpacing.sectionGap),
            const _StatCardsRow(),
            const SizedBox(height: AppSpacing.sectionGap),
            Text(
              'Groupes sanguins en tension',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const _TensionBars(),
            const SizedBox(height: AppSpacing.sectionGap),
            Text(
              'Activité récente',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const _RecentActivity(),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.structureName});

  final String structureName;

  String get _initials {
    final words = structureName.trim().split(RegExp(r'\s+'));
    final letters = words
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase());
    return letters.isEmpty ? '?' : letters.join();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(structureName, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('Bonjour 👋', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primaryLight,
          child: Text(
            _initials,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCardsRow extends ConsumerWidget {
  const _StatCardsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donorsAsync = ref.watch(donorsListProvider);
    final demandesAsync = ref.watch(activeDemandesProvider);
    final stockAlerts = ref.watch(stockAlertCountProvider);
    final stockLoading = ref.watch(stockListProvider).isLoading;

    final isLoading =
        (donorsAsync.isLoading && !donorsAsync.hasValue) ||
        (demandesAsync.isLoading && !demandesAsync.hasValue) ||
        (stockLoading && ref.watch(stockListProvider).value == null);

    if (isLoading) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          if (wide) {
            return const Row(
              children: [
                Expanded(child: _StatCardSkeleton()),
                SizedBox(width: 12),
                Expanded(child: _StatCardSkeleton()),
                SizedBox(width: 12),
                Expanded(child: _StatCardSkeleton()),
              ],
            );
          }
          return const Column(
            children: [
              Row(
                children: [
                  Expanded(child: _StatCardSkeleton()),
                  SizedBox(width: 12),
                  Expanded(child: _StatCardSkeleton()),
                ],
              ),
              SizedBox(height: 12),
              _StatCardSkeleton(),
            ],
          );
        },
      );
    }

    final donorsCount = donorsAsync.value?.length ?? 0;
    final demandesCount = demandesAsync.value?.length ?? 0;

    final card1 = _StatCard(
      icon: Icons.people_outline,
      iconColor: AppColors.secondary,
      value: '$donorsCount',
      label: 'Donneurs enregistrés',
      onTap: () => context.go('/donors'),
    );
    final card2 = _StatCard(
      icon: Icons.campaign_outlined,
      iconColor: AppColors.secondary,
      value: '$demandesCount',
      label: 'Demandes en cours',
      showPulse: demandesCount > 0,
      onTap: () => context.go('/requests'),
    );
    final card3 = _StatCard(
      icon: Icons.warning_amber_outlined,
      iconColor: stockAlerts > 0 ? AppColors.alert : AppColors.textDisabled,
      value: '$stockAlerts',
      label: 'Alertes de stock',
      onTap: () => context.go('/stock'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        if (wide) {
          return Row(
            children: [
              Expanded(child: card1),
              const SizedBox(width: 12),
              Expanded(child: card2),
              const SizedBox(width: 12),
              Expanded(child: card3),
            ],
          );
        }
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: card1),
                const SizedBox(width: 12),
                Expanded(child: card2),
              ],
            ),
            const SizedBox(height: 12),
            card3,
          ],
        );
      },
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: kCardShadow,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 28, height: 28, borderRadius: 8),
          Spacer(),
          SkeletonBox(width: 40, height: 22),
          SizedBox(height: 6),
          SkeletonBox(width: 100, height: 12),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.showPulse = false,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool showPulse;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: kCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: iconColor, size: 26),
                if (showPulse)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _TensionBars extends ConsumerWidget {
  const _TensionBars();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockAsync = ref.watch(stockListProvider);

    if (stockAsync.isLoading && !stockAsync.hasValue) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: kCardShadow,
        ),
        child: Column(
          children: List.generate(
            4,
            (_) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: SkeletonBox(height: 14),
            ),
          ),
        ),
      );
    }

    final items = stockAsync.value ?? const <StockItem>[];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: kCardShadow,
      ),
      child: Column(
        children: [for (final item in items) _TensionRow(item: item)],
      ),
    );
  }
}

class _TensionRow extends StatelessWidget {
  const _TensionRow({required this.item});

  final StockItem item;

  Color get _barColor => switch (item.niveau) {
    StockLevel.normal => AppColors.success,
    StockLevel.moyen => AppColors.alert,
    StockLevel.critique => AppColors.danger,
  };

  @override
  Widget build(BuildContext context) {
    final ratio = item.pourcentageObjectif.clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              item.groupeSanguin,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: ratio),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation(_barColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 56,
            child: Text(
              '${item.quantite} poches',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivity extends ConsumerWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(recentActivityProvider);

    return activityAsync.when(
      loading: () => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: kCardShadow,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const SkeletonList(count: 4),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (events) {
        if (events.isEmpty) {
          return const EmptyStateView(
            icon: Icons.history_rounded,
            title: 'Aucune activité récente',
            message: 'Créez votre première demande pour commencer.',
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: kCardShadow,
          ),
          child: Column(
            children: [
              for (final event in events)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(event.icon, size: 20, color: AppColors.secondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          event.description,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatRelativeTime(event.timestamp),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
