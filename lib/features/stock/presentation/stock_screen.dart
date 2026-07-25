import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_emergency/core/constants/app_constants.dart';
import 'package:health_emergency/core/theme/app_theme.dart';
import 'package:health_emergency/core/widgets/blood_type_badge.dart';
import 'package:health_emergency/core/widgets/skeleton_loader.dart';
import 'package:health_emergency/features/stock/application/stock_providers.dart';
import 'package:health_emergency/features/stock/data/stock_model.dart';
import 'package:health_emergency/features/stock/presentation/widgets/stock_movement_dialog.dart';
import 'package:health_emergency/features/stock/presentation/widgets/stock_thresholds_sheet.dart';
import 'package:intl/intl.dart';

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  String? _historyFilter;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < kMobileBreakpoint;
    final stockAsync = ref.watch(stockListProvider);
    final historyAsync = ref.watch(stockHistoryProvider(_historyFilter));

    return SafeArea(
      child: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? AppSpacing.screenPaddingMobile : AppSpacing.screenPaddingWeb,
          vertical: AppSpacing.sectionGap,
        ),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Banque de sang', style: Theme.of(context).textTheme.headlineSmall),
              TextButton.icon(
                onPressed: stockAsync.value == null
                    ? null
                    : () => showStockThresholdsSheet(context, stockAsync.value!),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Configurer les seuils'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          stockAsync.when(
            loading: () => GridView.count(
              crossAxisCount: isMobile ? 2 : 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: List.generate(8, (_) => const _StockCardSkeleton()),
            ),
            error: (e, _) => Text('Erreur : $e'),
            data: (items) => GridView.count(
              crossAxisCount: isMobile ? 2 : 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: [for (final item in items) _StockCard(item: item)],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          Text('Historique des mouvements', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: const Text('Tous'),
                  selected: _historyFilter == null,
                  onSelected: (_) => setState(() => _historyFilter = null),
                ),
                const SizedBox(width: 8),
                for (final bt in kBloodTypes) ...[
                  ChoiceChip(
                    label: Text(bt.label),
                    selected: _historyFilter == bt.value,
                    onSelected: (_) => setState(() => _historyFilter = bt.value),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          historyAsync.when(
            loading: () => const SizedBox(
              height: 200,
              child: SkeletonList(count: 4),
            ),
            error: (e, _) => Text('Erreur : $e'),
            data: (movements) {
              if (movements.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Aucun mouvement enregistré.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
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
                    for (final m in movements)
                      ListTile(
                        leading: Icon(
                          m.type == MouvementType.entree
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: m.type == MouvementType.entree
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                        title: Row(
                          children: [
                            BloodTypeBadge(label: m.groupeSanguin, small: true),
                            const SizedBox(width: 8),
                            Text(m.motif),
                          ],
                        ),
                        subtitle: Text(
                          m.date != null ? DateFormat('dd/MM/yyyy HH:mm').format(m.date!) : '—',
                        ),
                        trailing: Text(
                          '${m.type == MouvementType.entree ? '+' : '-'}${m.quantite}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: m.type == MouvementType.entree
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StockCardSkeleton extends StatelessWidget {
  const _StockCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: kCardShadow,
      ),
      child: const Column(
        children: [
          SkeletonBox(width: 40, height: 20),
          Spacer(),
          SkeletonBox(width: 64, height: 64, borderRadius: 32),
          Spacer(),
        ],
      ),
    );
  }
}

class _StockCard extends StatelessWidget {
  const _StockCard({required this.item});

  final StockItem item;

  Color get _color => switch (item.niveau) {
    StockLevel.normal => AppColors.success,
    StockLevel.moyen => AppColors.alert,
    StockLevel.critique => AppColors.danger,
  };

  @override
  Widget build(BuildContext context) {
    final ratio = item.pourcentageObjectif.clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: kCardShadow,
      ),
      child: Column(
        children: [
          Text(
            item.groupeSanguin,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          Expanded(
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: ratio),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: value,
                        strokeWidth: 7,
                        backgroundColor: AppColors.background,
                        valueColor: AlwaysStoppedAnimation(_color),
                      ),
                      Text(
                        '${item.quantite}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Text('poches', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.danger),
                tooltip: 'Retirer',
                onPressed: () => showStockMovementDialog(
                  context,
                  groupeSanguin: item.groupeSanguin,
                  type: MouvementType.sortie,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.add_circle_outline, color: AppColors.success),
                tooltip: 'Ajouter',
                onPressed: () => showStockMovementDialog(
                  context,
                  groupeSanguin: item.groupeSanguin,
                  type: MouvementType.entree,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
