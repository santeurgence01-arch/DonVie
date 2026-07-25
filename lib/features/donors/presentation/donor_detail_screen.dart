import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:health_emergency/core/theme/app_theme.dart';
import 'package:health_emergency/core/widgets/blood_type_badge.dart';
import 'package:health_emergency/features/donors/application/donor_providers.dart';
import 'package:health_emergency/features/donors/data/donor_model.dart';
import 'package:health_emergency/features/onboarding/application/onboarding_providers.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class DonorDetailScreen extends ConsumerWidget {
  const DonorDetailScreen({super.key, required this.donorId});

  final String donorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final donorAsync = ref.watch(donorDetailProvider(donorId));

    return Scaffold(
      appBar: AppBar(title: const Text('Détail du donneur')),
      body: donorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (donor) {
          if (donor == null) {
            return const Center(child: Text('Ce donneur est introuvable.'));
          }
          return _DonorDetailBody(donor: donor);
        },
      ),
    );
  }
}

class _DonorDetailBody extends ConsumerWidget {
  const _DonorDetailBody({required this.donor});

  final DonorModel donor;

  Future<void> _call(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: donor.telephone);
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible de lancer l'appel.")),
        );
      }
    }
  }

  Future<void> _confirmToggleActive(BuildContext context, WidgetRef ref) async {
    final becomingInactive = donor.actif;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(becomingInactive ? 'Désactiver ce donneur ?' : 'Réactiver ce donneur ?'),
        content: Text(
          becomingInactive
              ? 'Ce donneur ne recevra plus de notifications tant qu\'il n\'est pas réactivé.'
              : 'Ce donneur recevra à nouveau les notifications de demandes compatibles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(becomingInactive ? 'Désactiver' : 'Réactiver'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(donorRepositoryProvider)
          .setActive(donor.id, !donor.actif);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final structureName = ref.watch(structureDocProvider).value?.nom ?? '—';
    final historyAsync = ref.watch(donorHistoryProvider(donor.id));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  donor.initiales,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(donor.nomComplet, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              BloodTypeBadge(label: donor.groupeSanguin),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Informations', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: kCardShadow,
          ),
          child: Column(
            children: [
              _InfoRow(icon: Icons.cake_outlined, label: 'Âge', value: '${donor.age} ans'),
              const Divider(height: 24),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Téléphone',
                value: donor.telephone,
                trailing: IconButton(
                  icon: const Icon(Icons.call_rounded, color: AppColors.secondary),
                  onPressed: () => _call(context),
                  tooltip: 'Appeler',
                ),
              ),
              const Divider(height: 24),
              _InfoRow(
                icon: Icons.place_outlined,
                label: 'Localisation',
                value: donor.adresse?.isNotEmpty == true ? donor.adresse! : 'Non renseignée',
              ),
              if (donor.localisation != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  child: SizedBox(
                    height: 140,
                    child: IgnorePointer(
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            donor.localisation!.latitude,
                            donor.localisation!.longitude,
                          ),
                          zoom: 13,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('donor'),
                            position: LatLng(
                              donor.localisation!.latitude,
                              donor.localisation!.longitude,
                            ),
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
                ),
              ],
              const Divider(height: 24),
              _InfoRow(
                icon: Icons.event_outlined,
                label: "Date d'enregistrement",
                value: donor.createdAt != null
                    ? DateFormat('dd/MM/yyyy').format(donor.createdAt!)
                    : '—',
              ),
              const Divider(height: 24),
              _InfoRow(
                icon: Icons.local_hospital_outlined,
                label: "Structure d'enregistrement",
                value: structureName,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Historique des dons de ce donneur', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        historyAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Erreur : $e'),
          data: (history) {
            if (history.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  boxShadow: kCardShadow,
                ),
                child: Text(
                  'Aucun don enregistré pour ce donneur.',
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
                  for (final mvt in history)
                    ListTile(
                      leading: const Icon(Icons.water_drop_rounded, color: AppColors.primary),
                      title: Text(
                        mvt.date != null
                            ? DateFormat('dd/MM/yyyy').format(mvt.date!)
                            : '—',
                      ),
                      trailing: Text('${mvt.quantite} poche(s)'),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        Center(
          child: TextButton(
            onPressed: () => _confirmToggleActive(context, ref),
            style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            child: Text(donor.actif ? 'Désactiver ce donneur' : 'Réactiver ce donneur'),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
        trailing ?? const SizedBox.shrink(),
      ],
    );
  }
}
