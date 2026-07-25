import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:health_emergency/core/constants/app_constants.dart';
import 'package:health_emergency/core/providers/current_structure_provider.dart';
import 'package:health_emergency/features/onboarding/application/onboarding_providers.dart';
import 'package:health_emergency/features/requests/application/requests_providers.dart';
import 'package:health_emergency/features/requests/data/demande_model.dart';

class RequestWizardState {
  const RequestWizardState({
    this.currentStep = 1,
    this.groupesSanguins = const {},
    this.niveauUrgence,
    this.rayonKm = 5,
    this.matchingCount = 0,
    this.radiusMatchingCount = 0,
    this.isCountingRadius = false,
    this.isSubmitting = false,
    this.submitError,
  });

  final int currentStep;
  final Set<String> groupesSanguins;
  final UrgencyLevel? niveauUrgence;
  final double rayonKm;
  final int matchingCount;
  final int radiusMatchingCount;
  final bool isCountingRadius;
  final bool isSubmitting;
  final String? submitError;

  bool get step1Valid => groupesSanguins.isNotEmpty;
  bool get step2Valid => niveauUrgence != null;
  bool get step3Valid => true;

  RequestWizardState copyWith({
    int? currentStep,
    Set<String>? groupesSanguins,
    UrgencyLevel? niveauUrgence,
    double? rayonKm,
    int? matchingCount,
    int? radiusMatchingCount,
    bool? isCountingRadius,
    bool? isSubmitting,
    String? submitError,
    bool clearError = false,
  }) {
    return RequestWizardState(
      currentStep: currentStep ?? this.currentStep,
      groupesSanguins: groupesSanguins ?? this.groupesSanguins,
      niveauUrgence: niveauUrgence ?? this.niveauUrgence,
      rayonKm: rayonKm ?? this.rayonKm,
      matchingCount: matchingCount ?? this.matchingCount,
      radiusMatchingCount: radiusMatchingCount ?? this.radiusMatchingCount,
      isCountingRadius: isCountingRadius ?? this.isCountingRadius,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearError ? null : (submitError ?? this.submitError),
    );
  }
}

final requestWizardControllerProvider =
    StateNotifierProvider.autoDispose<RequestWizardController, RequestWizardState>((ref) {
      return RequestWizardController(ref);
    });

class RequestWizardController extends StateNotifier<RequestWizardState> {
  RequestWizardController(this._ref) : super(const RequestWizardState());

  final Ref _ref;
  Timer? _radiusDebounce;

  void toggleBloodType(String value) {
    final next = Set<String>.from(state.groupesSanguins);
    if (!next.remove(value)) next.add(value);
    state = state.copyWith(groupesSanguins: next);
    _refreshMatchingCount();
  }

  void setUrgency(UrgencyLevel value) => state = state.copyWith(niveauUrgence: value);

  void setRayon(double value) {
    state = state.copyWith(rayonKm: value);
    _radiusDebounce?.cancel();
    _radiusDebounce = Timer(const Duration(milliseconds: 400), _refreshRadiusCount);
  }

  void nextStep() {
    if (state.currentStep < 4) {
      state = state.copyWith(currentStep: state.currentStep + 1);
      if (state.currentStep == 3) _refreshRadiusCount();
    }
  }

  void previousStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  Future<void> _refreshMatchingCount() async {
    final structureId = _ref.read(currentStructureIdProvider);
    if (structureId == null || state.groupesSanguins.isEmpty) {
      state = state.copyWith(matchingCount: 0);
      return;
    }
    final donors = await _ref.read(demandeRepositoryProvider).matchingDonors(
          structureId: structureId,
          groupesSanguins: state.groupesSanguins.toList(),
        );
    state = state.copyWith(matchingCount: donors.length);
  }

  Future<void> _refreshRadiusCount() async {
    final structureId = _ref.read(currentStructureIdProvider);
    final centre = _ref.read(structureDocProvider).value?.localisation;
    if (structureId == null || centre == null || state.groupesSanguins.isEmpty) {
      state = state.copyWith(radiusMatchingCount: 0);
      return;
    }
    state = state.copyWith(isCountingRadius: true);
    final donors = await _ref.read(demandeRepositoryProvider).matchingDonorsInRadius(
          structureId: structureId,
          groupesSanguins: state.groupesSanguins.toList(),
          centre: centre,
          rayonKm: state.rayonKm,
        );
    state = state.copyWith(radiusMatchingCount: donors.length, isCountingRadius: false);
  }

  Future<DemandeModel?> submit() async {
    final structureId = _ref.read(currentStructureIdProvider);
    final centre = _ref.read(structureDocProvider).value?.localisation;
    if (structureId == null || centre == null || state.niveauUrgence == null) return null;

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final demande = await _ref.read(demandeRepositoryProvider).creerEtDiffuser(
            structureId: structureId,
            groupesSanguins: state.groupesSanguins.toList(),
            niveauUrgence: state.niveauUrgence!,
            rayonKm: state.rayonKm,
            centre: centre,
          );
      state = state.copyWith(isSubmitting: false);
      return demande;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, submitError: e.toString());
      return null;
    }
  }

  @override
  void dispose() {
    _radiusDebounce?.cancel();
    super.dispose();
  }
}
