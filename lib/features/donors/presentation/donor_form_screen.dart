import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:health_emergency/core/constants/app_constants.dart';
import 'package:health_emergency/core/theme/app_theme.dart';
import 'package:health_emergency/core/widgets/app_text_field.dart';
import 'package:health_emergency/core/widgets/blood_type_chip.dart';
import 'package:health_emergency/core/widgets/primary_button.dart';
import 'package:health_emergency/core/providers/current_structure_provider.dart';
import 'package:health_emergency/features/donors/application/donor_providers.dart';
import 'package:health_emergency/features/donors/presentation/widgets/donor_result_modal.dart';
import 'package:health_emergency/features/donors/presentation/widgets/location_picker_dialog.dart';
import 'package:health_emergency/features/onboarding/application/onboarding_providers.dart';

final _phoneRegex = RegExp(r'^[0-9+\s-]{8,20}$');
const _fallbackPosition = LatLng(4.0511, 9.7679);

class DonorFormScreen extends ConsumerStatefulWidget {
  const DonorFormScreen({super.key});

  @override
  ConsumerState<DonorFormScreen> createState() => _DonorFormScreenState();
}

class _DonorFormScreenState extends ConsumerState<DonorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _ageController = TextEditingController();
  final _telephoneController = TextEditingController();

  LatLng? _localisation;
  String? _adresse;
  String? _groupeSanguin;
  bool _showBloodTypeError = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _ageController.dispose();
    _telephoneController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final structureLocation = ref.read(structureDocProvider).value?.localisation;
    final initial = _localisation ??
        (structureLocation != null
            ? LatLng(structureLocation.latitude, structureLocation.longitude)
            : _fallbackPosition);
    final picked = await showLocationPickerDialog(context, initialPosition: initial);
    if (picked == null) return;

    setState(() {
      _localisation = picked;
      _adresse = null;
    });
    try {
      final placemarks = await geocoding.Geocoding().placemarkFromCoordinates(
        picked.latitude,
        picked.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        setState(() {
          _adresse = [p.locality, p.administrativeArea, p.country]
              .where((s) => s != null && s.isNotEmpty)
              .join(', ');
        });
      }
    } catch (_) {
      // Adresse non résolue — la position reste néanmoins enregistrée.
    }
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    final bloodTypeValid = _groupeSanguin != null;
    if (!bloodTypeValid) setState(() => _showBloodTypeError = true);
    if (!formValid || !bloodTypeValid) return;

    final structureId = ref.read(currentStructureIdProvider);
    if (structureId == null) return;

    setState(() => _isSubmitting = true);
    try {
      final donor = await ref.read(donorRepositoryProvider).createDonor(
            structureId: structureId,
            nom: _nomController.text.trim(),
            prenom: _prenomController.text.trim(),
            age: int.parse(_ageController.text.trim()),
            telephone: _telephoneController.text.trim(),
            groupeSanguin: _groupeSanguin!,
            localisation: _localisation != null
                ? GeoPoint(_localisation!.latitude, _localisation!.longitude)
                : null,
            adresse: _adresse,
          );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      HapticFeedback.mediumImpact();
      final structureName = ref.read(structureDocProvider).value?.nom ?? 'votre structure';
      await showDonorResultModal(context, donor: donor, structureName: structureName);

      if (mounted) context.pop(donor.id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Échec de l'enregistrement : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau donneur')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Nom',
                  controller: _nomController,
                  semanticsLabel: 'Nom',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Le nom est requis.' : null,
                ),
                const SizedBox(height: AppSpacing.fieldGap),
                AppTextField(
                  label: 'Prénom',
                  controller: _prenomController,
                  semanticsLabel: 'Prénom',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Le prénom est requis.' : null,
                ),
                const SizedBox(height: AppSpacing.fieldGap),
                AppTextField(
                  label: 'Âge',
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  semanticsLabel: 'Âge',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return "L'âge est requis.";
                    final age = int.tryParse(v.trim());
                    if (age == null) return 'Âge invalide.';
                    if (age < 18 || age > 65) {
                      return 'Le donneur doit avoir entre 18 et 65 ans.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.fieldGap),
                AppTextField(
                  label: 'Téléphone',
                  controller: _telephoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  semanticsLabel: 'Téléphone',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Le téléphone est requis.';
                    }
                    if (!_phoneRegex.hasMatch(v.trim())) {
                      return 'Numéro de téléphone invalide.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.fieldGap),
                OutlinedButton.icon(
                  onPressed: _pickLocation,
                  icon: const Icon(Icons.place_outlined),
                  label: Text(
                    _localisation == null
                        ? 'Localiser sur la carte'
                        : (_adresse ?? 'Position enregistrée'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                Text('Groupe sanguin', style: Theme.of(context).textTheme.titleLarge),
                if (_showBloodTypeError && _groupeSanguin == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Sélectionnez un groupe sanguin.',
                      style: TextStyle(color: AppColors.danger, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final bt in kBloodTypes)
                      BloodTypeChip(
                        label: bt.label,
                        selected: _groupeSanguin == bt.value,
                        onTap: () => setState(() {
                          _groupeSanguin = bt.value;
                          _showBloodTypeError = false;
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                PrimaryButton(
                  label: "Enregistrer et générer l'identifiant",
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
