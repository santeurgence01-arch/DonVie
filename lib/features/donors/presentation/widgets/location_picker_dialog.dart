import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:health_emergency/core/theme/app_theme.dart';
import 'package:health_emergency/core/widgets/primary_button.dart';

/// Mini-carte modale avec marqueur déplaçable — §4.4.3 "Localiser sur la
/// carte". Retourne la position choisie, ou `null` si annulé.
Future<LatLng?> showLocationPickerDialog(
  BuildContext context, {
  required LatLng initialPosition,
}) {
  return showDialog<LatLng>(
    context: context,
    builder: (context) => _LocationPickerDialog(initialPosition: initialPosition),
  );
}

class _LocationPickerDialog extends StatefulWidget {
  const _LocationPickerDialog({required this.initialPosition});

  final LatLng initialPosition;

  @override
  State<_LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<_LocationPickerDialog> {
  late LatLng _position = widget.initialPosition;
  bool _locating = false;

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final permission = await Geolocator.checkPermission();
      var granted = permission;
      if (permission == LocationPermission.denied) {
        granted = await Geolocator.requestPermission();
      }
      if (granted == LocationPermission.always ||
          granted == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition();
        setState(() => _position = LatLng(pos.latitude, pos.longitude));
      }
    } catch (_) {
      // Position conservée en cas d'échec.
    }
    if (mounted) setState(() => _locating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Localiser sur la carte', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.control),
              child: SizedBox(
                height: 260,
                width: 360,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(target: _position, zoom: 14),
                      markers: {
                        Marker(
                          markerId: const MarkerId('picked'),
                          position: _position,
                          draggable: true,
                          onDragEnd: (p) => setState(() => _position = p),
                        ),
                      },
                      onTap: (p) => setState(() => _position = p),
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: FloatingActionButton.small(
                        heroTag: 'locate-me',
                        onPressed: _useCurrentLocation,
                        backgroundColor: AppColors.surface,
                        child: _locating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location_rounded, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Faites glisser le marqueur pour ajuster la position.',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Confirmer',
                    onPressed: () => Navigator.pop(context, _position),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
