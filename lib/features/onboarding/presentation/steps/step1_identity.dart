import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:health_emergency/core/constants/app_constants.dart';
import 'package:health_emergency/core/theme/app_theme.dart';
import 'package:health_emergency/core/widgets/app_text_field.dart';
import 'package:health_emergency/features/onboarding/application/onboarding_providers.dart';

/// Position par défaut si la géolocalisation n'est pas disponible
/// (centre approximatif — à ajuster selon la zone de déploiement réelle).
const _fallbackPosition = LatLng(4.0511, 9.7679);

class Step1Identity extends ConsumerStatefulWidget {
  const Step1Identity({super.key});

  @override
  ConsumerState<Step1Identity> createState() => _Step1IdentityState();
}

class _Step1IdentityState extends ConsumerState<Step1Identity> {
  final _nomController = TextEditingController();
  final _adresseController = TextEditingController();
  GoogleMapController? _mapController;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingControllerProvider);
    _nomController.text = state.nom;
    _adresseController.text = state.adresse;
    if (state.localisation == null) {
      _centerOnCurrentLocation();
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  Future<void> _centerOnCurrentLocation() async {
    setState(() => _locating = true);
    LatLng target = _fallbackPosition;
    try {
      final permission = await Geolocator.checkPermission();
      var granted = permission;
      if (permission == LocationPermission.denied) {
        granted = await Geolocator.requestPermission();
      }
      if (granted == LocationPermission.always ||
          granted == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition();
        target = LatLng(position.latitude, position.longitude);
      }
    } catch (_) {
      // Position par défaut conservée en cas d'échec (permission refusée,
      // service désactivé, plateforme non supportée...).
    }
    if (!mounted) return;
    setState(() => _locating = false);
    ref.read(onboardingControllerProvider.notifier).setLocalisation(target);
    _mapController?.animateCamera(CameraUpdate.newLatLng(target));
  }

  Future<void> _geocodeAddress(String adresse) async {
    if (adresse.trim().isEmpty) return;
    try {
      final results = await geocoding.Geocoding().locationFromAddress(adresse);
      if (results.isEmpty || !mounted) return;
      final target = LatLng(results.first.latitude, results.first.longitude);
      ref.read(onboardingControllerProvider.notifier).setLocalisation(target);
      _mapController?.animateCamera(CameraUpdate.newLatLng(target));
    } catch (_) {
      // Adresse non géocodable — l'utilisateur peut ajuster le marqueur
      // manuellement sur la carte.
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final showErrors = state.showStep1Errors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'Nom de la structure',
          controller: _nomController,
          maxLength: 100,
          showCounter: true,
          onChanged: controller.setNom,
          validator: (value) {
            if (!showErrors) return null;
            if (value == null || value.trim().isEmpty) {
              return 'Le nom de la structure est requis.';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.fieldGap),
        DropdownButtonFormField<String>(
          initialValue: state.structureType,
          decoration: const InputDecoration(labelText: 'Type de structure'),
          items: kStructureTypes
              .map(
                (t) => DropdownMenuItem(value: t.value, child: Text(t.label)),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) controller.setType(value);
          },
          validator: (value) {
            if (!showErrors) return null;
            if (value == null) return 'Le type de structure est requis.';
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.fieldGap),
        AppTextField(
          label: 'Adresse',
          controller: _adresseController,
          prefixIcon: Icons.place_outlined,
          onChanged: (value) {
            controller.setAdresse(value);
          },
          suffixIcon: IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Localiser cette adresse',
            onPressed: () => _geocodeAddress(_adresseController.text),
          ),
        ),
        const SizedBox(height: AppSpacing.fieldGap),
        if (showErrors && state.localisation == null)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Positionnez la structure sur la carte.',
              style: TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: SizedBox(
            height: 220,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: state.localisation ?? _fallbackPosition,
                    zoom: 14,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  markers: {
                    Marker(
                      markerId: const MarkerId('structure'),
                      position: state.localisation ?? _fallbackPosition,
                      draggable: true,
                      onDragEnd: (position) => ref
                          .read(onboardingControllerProvider.notifier)
                          .setLocalisation(position),
                    ),
                  },
                  onTap: (position) => ref
                      .read(onboardingControllerProvider.notifier)
                      .setLocalisation(position),
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                ),
                if (_locating)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Faites glisser le marqueur pour ajuster précisément la position.',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ],
    );
  }
}
