import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:health_emergency/core/theme/app_theme.dart';
import 'package:health_emergency/features/onboarding/application/onboarding_providers.dart';
import 'package:health_emergency/features/requests/application/request_wizard_providers.dart';

class RequestStep3Zone extends ConsumerWidget {
  const RequestStep3Zone({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(requestWizardControllerProvider);
    final controller = ref.read(requestWizardControllerProvider.notifier);
    final structureLocation = ref.watch(structureDocProvider).value?.localisation;
    final center = structureLocation != null
        ? LatLng(structureLocation.latitude, structureLocation.longitude)
        : const LatLng(4.0511, 9.7679);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Dans quelle zone chercher des donneurs ?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: SizedBox(
            height: 320,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: center, zoom: 11),
              markers: {Marker(markerId: const MarkerId('structure'), position: center)},
              circles: {
                Circle(
                  circleId: const CircleId('rayon'),
                  center: center,
                  radius: state.rayonKm * 1000,
                  fillColor: AppColors.primary.withValues(alpha: 0.12),
                  strokeColor: AppColors.primary,
                  strokeWidth: 2,
                ),
              },
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Rayon de recherche : ${state.rayonKm.round()} km',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Slider(
          value: state.rayonKm,
          min: 1,
          max: 50,
          divisions: 49,
          onChanged: controller.setRayon,
        ),
        const SizedBox(height: 8),
        if (state.isCountingRadius)
          const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else
          Text(
            '${state.radiusMatchingCount} donneur${state.radiusMatchingCount > 1 ? 's' : ''} compatible${state.radiusMatchingCount > 1 ? 's' : ''} trouvé${state.radiusMatchingCount > 1 ? 's' : ''} dans cette zone',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        if (!state.isCountingRadius && state.radiusMatchingCount == 0) ...[
          const SizedBox(height: 8),
          Text(
            'Aucun donneur dans cette zone, essayez d\'élargir le rayon.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}
