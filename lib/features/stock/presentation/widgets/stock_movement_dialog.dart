import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_emergency/core/constants/app_constants.dart';
import 'package:health_emergency/core/providers/current_structure_provider.dart';
import 'package:health_emergency/core/theme/app_theme.dart';
import 'package:health_emergency/core/widgets/primary_button.dart';
import 'package:health_emergency/features/stock/application/stock_providers.dart';
import 'package:health_emergency/features/stock/data/stock_repository.dart';

const _kMotifsEntree = ['Don reçu', 'Correction', 'Autre'];
const _kMotifsSortie = ['Utilisation médicale', 'Péremption', 'Autre'];

/// Modale légère d'ajout/retrait de stock — §4.5, avec motif obligatoire.
Future<void> showStockMovementDialog(
  BuildContext context, {
  required String groupeSanguin,
  required MouvementType type,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _StockMovementDialog(groupeSanguin: groupeSanguin, type: type),
  );
}

class _StockMovementDialog extends ConsumerStatefulWidget {
  const _StockMovementDialog({required this.groupeSanguin, required this.type});

  final String groupeSanguin;
  final MouvementType type;

  @override
  ConsumerState<_StockMovementDialog> createState() => _StockMovementDialogState();
}

class _StockMovementDialogState extends ConsumerState<_StockMovementDialog> {
  final _quantiteController = TextEditingController(text: '1');
  final _autreMotifController = TextEditingController();
  String? _motif;
  bool _isSubmitting = false;
  String? _error;

  bool get _isEntree => widget.type == MouvementType.entree;

  @override
  void initState() {
    super.initState();
    _motif = (_isEntree ? _kMotifsEntree : _kMotifsSortie).first;
  }

  @override
  void dispose() {
    _quantiteController.dispose();
    _autreMotifController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final quantite = int.tryParse(_quantiteController.text.trim());
    if (quantite == null || quantite <= 0) {
      setState(() => _error = 'Quantité invalide.');
      return;
    }
    final motif = _motif == 'Autre' ? _autreMotifController.text.trim() : _motif!;
    if (motif.isEmpty) {
      setState(() => _error = 'Précisez un motif.');
      return;
    }

    final structureId = ref.read(currentStructureIdProvider);
    if (structureId == null) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(stockRepositoryProvider).applyMovement(
            structureId: structureId,
            groupeSanguin: widget.groupeSanguin,
            type: widget.type,
            quantite: quantite,
            motif: motif,
          );
      if (mounted) Navigator.pop(context);
    } on InsufficientStockException {
      setState(() {
        _isSubmitting = false;
        _error = 'Quantité insuffisante en stock.';
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _error = "Une erreur est survenue.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final motifs = _isEntree ? _kMotifsEntree : _kMotifsSortie;
    return AlertDialog(
      title: Text(
        _isEntree
            ? 'Ajouter au stock — ${widget.groupeSanguin}'
            : 'Retirer du stock — ${widget.groupeSanguin}',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _quantiteController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantité (poches)'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _motif,
            decoration: const InputDecoration(labelText: 'Motif'),
            items: motifs.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setState(() => _motif = v),
          ),
          if (_motif == 'Autre') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _autreMotifController,
              decoration: const InputDecoration(labelText: 'Précisez le motif'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        PrimaryButton(label: 'Confirmer', isLoading: _isSubmitting, onPressed: _submit),
      ],
    );
  }
}
