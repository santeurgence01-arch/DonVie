import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_emergency/core/providers/current_structure_provider.dart';
import 'package:health_emergency/core/theme/app_theme.dart';
import 'package:health_emergency/core/widgets/primary_button.dart';
import 'package:health_emergency/features/stock/application/stock_providers.dart';
import 'package:health_emergency/features/stock/data/stock_model.dart';

/// "Configurer les seuils" — §4.5 : un champ numérique de seuil d'alerte
/// (+ objectif, utilisé pour la jauge circulaire) par groupe sanguin.
Future<void> showStockThresholdsSheet(BuildContext context, List<StockItem> items) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
    ),
    builder: (context) => _ThresholdsSheet(items: items),
  );
}

class _ThresholdsSheet extends ConsumerStatefulWidget {
  const _ThresholdsSheet({required this.items});

  final List<StockItem> items;

  @override
  ConsumerState<_ThresholdsSheet> createState() => _ThresholdsSheetState();
}

class _ThresholdsSheetState extends ConsumerState<_ThresholdsSheet> {
  late final Map<String, TextEditingController> _seuilControllers = {
    for (final item in widget.items)
      item.groupeSanguin: TextEditingController(text: '${item.seuilAlerte}'),
  };
  late final Map<String, TextEditingController> _objectifControllers = {
    for (final item in widget.items)
      item.groupeSanguin: TextEditingController(text: '${item.objectif}'),
  };
  bool _isSaving = false;

  @override
  void dispose() {
    for (final c in _seuilControllers.values) {
      c.dispose();
    }
    for (final c in _objectifControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final structureId = ref.read(currentStructureIdProvider);
    if (structureId == null) return;
    setState(() => _isSaving = true);
    final repo = ref.read(stockRepositoryProvider);
    for (final item in widget.items) {
      final seuil = int.tryParse(_seuilControllers[item.groupeSanguin]!.text) ?? item.seuilAlerte;
      final objectif =
          int.tryParse(_objectifControllers[item.groupeSanguin]!.text) ?? item.objectif;
      await repo.configureThresholds(
        structureId: structureId,
        groupeSanguin: item.groupeSanguin,
        seuilAlerte: seuil,
        objectif: objectif,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Configurer les seuils', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.5),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final item in widget.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 48,
                            child: Text(
                              item.groupeSanguin,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _seuilControllers[item.groupeSanguin],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Seuil d\'alerte'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _objectifControllers[item.groupeSanguin],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Objectif'),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Enregistrer', isLoading: _isSaving, onPressed: _save),
        ],
      ),
    );
  }
}
