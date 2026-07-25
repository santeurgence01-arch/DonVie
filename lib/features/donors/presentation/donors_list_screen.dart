import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:health_emergency/core/constants/app_constants.dart';
import 'package:health_emergency/core/theme/app_theme.dart';
import 'package:health_emergency/core/widgets/blood_type_badge.dart';
import 'package:health_emergency/core/widgets/empty_state_view.dart';
import 'package:health_emergency/core/widgets/skeleton_loader.dart';
import 'package:health_emergency/core/widgets/status_dot.dart';
import 'package:health_emergency/features/donors/application/donor_providers.dart';
import 'package:health_emergency/features/donors/data/donor_model.dart';
import 'package:health_emergency/features/onboarding/application/onboarding_providers.dart';

class DonorsListScreen extends ConsumerStatefulWidget {
  const DonorsListScreen({super.key});

  @override
  ConsumerState<DonorsListScreen> createState() => _DonorsListScreenState();
}

class _DonorsListScreenState extends ConsumerState<DonorsListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  final Set<String> _bloodTypeFilters = {};
  double? _maxDistanceKm;
  String? _highlightedId;
  Timer? _highlightTimer;

  @override
  void dispose() {
    _debounce?.cancel();
    _highlightTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addDonor() async {
    final newId = await context.push<String>('/donors/new');
    if (newId == null || !mounted) return;
    _highlightTimer?.cancel();
    setState(() => _highlightedId = newId);
    _highlightTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _highlightedId = null);
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _query = value.trim().toLowerCase());
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _query = '';
      _bloodTypeFilters.clear();
      _maxDistanceKm = null;
    });
  }

  Future<void> _openDistanceFilter() async {
    var localValue = _maxDistanceKm ?? 25;
    final result = await showModalBottomSheet<double?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                  Text(
                    'Filtrer par zone',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rayon maximal : ${localValue.round()} km',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Slider(
                    value: localValue,
                    min: 1,
                    max: 100,
                    divisions: 99,
                    onChanged: (v) => setSheetState(() => localValue = v),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, null),
                          child: const Text('Réinitialiser'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, localValue),
                          child: const Text('Appliquer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    setState(() => _maxDistanceKm = result);
  }

  double? _distanceFor(DonorModel donor, GeoPoint? structureLocation) {
    if (structureLocation == null || donor.localisation == null) return null;
    return Geolocator.distanceBetween(
          structureLocation.latitude,
          structureLocation.longitude,
          donor.localisation!.latitude,
          donor.localisation!.longitude,
        ) /
        1000;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < kMobileBreakpoint;
    final donorsAsync = ref.watch(donorsListProvider);
    final structureLocation = ref.watch(structureDocProvider).value?.localisation;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDonor,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajouter un donneur', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile
                ? AppSpacing.screenPaddingMobile
                : AppSpacing.screenPaddingWeb,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text('Donneurs', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Rechercher par nom ou téléphone',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    FilterChip(
                      label: const Text('Tous'),
                      selected: _bloodTypeFilters.isEmpty,
                      onSelected: (_) => setState(_bloodTypeFilters.clear),
                    ),
                    const SizedBox(width: 8),
                    for (final bt in kBloodTypes) ...[
                      FilterChip(
                        label: Text(bt.label),
                        selected: _bloodTypeFilters.contains(bt.value),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _bloodTypeFilters.add(bt.value);
                          } else {
                            _bloodTypeFilters.remove(bt.value);
                          }
                        }),
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton.filledTonal(
                      onPressed: _openDistanceFilter,
                      tooltip: 'Filtrer par zone',
                      icon: Icon(
                        Icons.tune_rounded,
                        color: _maxDistanceKm != null
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: donorsAsync.when(
                  loading: () => const SkeletonList(),
                  error: (e, _) => Center(
                    child: Text('Erreur de chargement : $e'),
                  ),
                  data: (allDonors) {
                    if (allDonors.isEmpty) {
                      return EmptyStateView(
                        icon: Icons.people_outline,
                        title: 'Aucun donneur enregistré pour le moment',
                        actionLabel: 'Ajouter votre premier donneur',
                        onAction: () => context.push('/donors/new'),
                      );
                    }

                    final filtered = allDonors.where((d) {
                      if (_query.isNotEmpty) {
                        final haystack =
                            '${d.nom} ${d.prenom} ${d.telephone}'.toLowerCase();
                        if (!haystack.contains(_query)) return false;
                      }
                      if (_bloodTypeFilters.isNotEmpty &&
                          !_bloodTypeFilters.contains(d.groupeSanguin)) {
                        return false;
                      }
                      if (_maxDistanceKm != null) {
                        final dist = _distanceFor(d, structureLocation);
                        if (dist == null || dist > _maxDistanceKm!) return false;
                      }
                      return true;
                    }).toList();

                    if (filtered.isEmpty) {
                      return EmptyStateView(
                        title: 'Aucun donneur ne correspond à ces critères',
                        secondaryActionLabel: 'Réinitialiser les filtres',
                        onSecondaryAction: _resetFilters,
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${filtered.length} donneur${filtered.length > 1 ? 's' : ''} trouvé${filtered.length > 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.only(bottom: 96, top: 8),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1, color: AppColors.border),
                            itemBuilder: (context, index) {
                              final donor = filtered[index];
                              final distance = _distanceFor(donor, structureLocation);
                              return _DonorTile(
                                donor: donor,
                                distanceKm: distance,
                                highlighted: donor.id == _highlightedId,
                              );
                            },
                          ),
                        ),
                      ],
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

class _DonorTile extends StatelessWidget {
  const _DonorTile({
    required this.donor,
    required this.distanceKm,
    this.highlighted = false,
  });

  final DonorModel donor;
  final double? distanceKm;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/donors/${donor.id}'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        color: highlighted ? AppColors.primaryLight : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    donor.initiales,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: StatusDot(active: donor.actif),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donor.nomComplet,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  BloodTypeBadge(label: donor.groupeSanguin, small: true),
                ],
              ),
            ),
            if (distanceKm != null)
              Text(
                '${distanceKm!.toStringAsFixed(1)} km',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }
}
