import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:health_emergency/features/auth/application/auth_providers.dart';
import 'package:health_emergency/features/onboarding/data/structure_model.dart';
import 'package:health_emergency/features/onboarding/data/structure_repository.dart';

final structureRepositoryProvider = Provider<StructureRepository>((ref) {
  return StructureRepository(FirebaseFirestore.instance, FirebaseStorage.instance);
});

/// Doc `structures/{uid}` de l'utilisateur connecté, null si pas connecté
/// ou si le document n'existe pas encore.
final structureDocProvider = StreamProvider<StructureModel?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(structureRepositoryProvider).watchStructure(user.uid);
});

enum DocumentUploadStatus { uploading, success, error }

class OnboardingDocument {
  const OnboardingDocument({
    required this.id,
    required this.fileName,
    required this.size,
    required this.contentType,
    required this.bytes,
    this.status = DocumentUploadStatus.uploading,
    this.progress = 0,
    this.uploaded,
  });

  final String id;
  final String fileName;
  final int size;
  final String contentType;
  final Uint8List bytes;
  final DocumentUploadStatus status;
  final double progress;
  final StructureDocument? uploaded;

  OnboardingDocument copyWith({
    DocumentUploadStatus? status,
    double? progress,
    StructureDocument? uploaded,
  }) {
    return OnboardingDocument(
      id: id,
      fileName: fileName,
      size: size,
      contentType: contentType,
      bytes: bytes,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      uploaded: uploaded ?? this.uploaded,
    );
  }
}

class OnboardingState {
  const OnboardingState({
    this.currentStep = 1,
    this.nom = '',
    this.structureType,
    this.adresse = '',
    this.localisation,
    this.documents = const [],
    this.groupesSanguins = const {},
    this.criteresAdditionnels = '',
    this.isSubmitting = false,
    this.submitError,
    this.showStep1Errors = false,
    this.showStep2Errors = false,
    this.showStep3Errors = false,
  });

  final int currentStep;
  final String nom;
  final String? structureType;
  final String adresse;
  final LatLng? localisation;
  final List<OnboardingDocument> documents;
  final Set<String> groupesSanguins;
  final String criteresAdditionnels;
  final bool isSubmitting;
  final String? submitError;
  final bool showStep1Errors;
  final bool showStep2Errors;
  final bool showStep3Errors;

  bool get step1Valid =>
      nom.trim().isNotEmpty && structureType != null && localisation != null;

  bool get step2Valid =>
      documents.any((d) => d.status == DocumentUploadStatus.success);

  bool get step3Valid => groupesSanguins.isNotEmpty;

  OnboardingState copyWith({
    int? currentStep,
    String? nom,
    String? structureType,
    String? adresse,
    LatLng? localisation,
    List<OnboardingDocument>? documents,
    Set<String>? groupesSanguins,
    String? criteresAdditionnels,
    bool? isSubmitting,
    String? submitError,
    bool clearSubmitError = false,
    bool? showStep1Errors,
    bool? showStep2Errors,
    bool? showStep3Errors,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      nom: nom ?? this.nom,
      structureType: structureType ?? this.structureType,
      adresse: adresse ?? this.adresse,
      localisation: localisation ?? this.localisation,
      documents: documents ?? this.documents,
      groupesSanguins: groupesSanguins ?? this.groupesSanguins,
      criteresAdditionnels: criteresAdditionnels ?? this.criteresAdditionnels,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      showStep1Errors: showStep1Errors ?? this.showStep1Errors,
      showStep2Errors: showStep2Errors ?? this.showStep2Errors,
      showStep3Errors: showStep3Errors ?? this.showStep3Errors,
    );
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
      return OnboardingController(ref);
    });

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController(this._ref) : super(const OnboardingState());

  final Ref _ref;
  int _localIdCounter = 0;

  StructureRepository get _repository => _ref.read(structureRepositoryProvider);

  String? get _uid => _ref.read(authStateProvider).value?.uid;

  void setNom(String value) => state = state.copyWith(nom: value);

  void setType(String value) => state = state.copyWith(structureType: value);

  void setAdresse(String value) => state = state.copyWith(adresse: value);

  void setLocalisation(LatLng value) =>
      state = state.copyWith(localisation: value);

  void setCriteres(String value) =>
      state = state.copyWith(criteresAdditionnels: value);

  void toggleBloodType(String value) {
    final next = Set<String>.from(state.groupesSanguins);
    if (!next.remove(value)) next.add(value);
    state = state.copyWith(groupesSanguins: next);
  }

  void goToStep(int step) => state = state.copyWith(currentStep: step);

  void nextStep() {
    if (state.currentStep == 1 && !state.step1Valid) {
      state = state.copyWith(showStep1Errors: true);
      return;
    }
    if (state.currentStep == 2 && !state.step2Valid) {
      state = state.copyWith(showStep2Errors: true);
      return;
    }
    if (state.currentStep < 3) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Retourne `true` si l'étape 3 est valide (l'appelant peut ouvrir la
  /// modale de récapitulatif) ; sinon révèle les messages d'erreur.
  bool attemptFinish() {
    if (!state.step3Valid) {
      state = state.copyWith(showStep3Errors: true);
      return false;
    }
    return true;
  }

  Future<void> addFiles(
    List<({String fileName, Uint8List bytes, String contentType})> files,
  ) async {
    final uid = _uid;
    if (uid == null) return;

    for (final file in files) {
      final id = 'doc_${_localIdCounter++}';
      final doc = OnboardingDocument(
        id: id,
        fileName: file.fileName,
        size: file.bytes.length,
        contentType: file.contentType,
        bytes: file.bytes,
      );
      state = state.copyWith(documents: [...state.documents, doc]);
      _startUpload(uid, id);
    }
  }

  Future<void> retryUpload(String id) async {
    final uid = _uid;
    if (uid == null) return;
    _updateDocument(id, (d) => d.copyWith(status: DocumentUploadStatus.uploading, progress: 0));
    await _startUpload(uid, id);
  }

  Future<void> _startUpload(String uid, String id) async {
    final doc = state.documents.firstWhere((d) => d.id == id);
    try {
      final uploaded = await _repository.uploadDocument(
        uid: uid,
        fileName: doc.fileName,
        bytes: doc.bytes,
        contentType: doc.contentType,
        onProgress: (progress) {
          _updateDocument(id, (d) => d.copyWith(progress: progress));
        },
      );
      _updateDocument(
        id,
        (d) => d.copyWith(status: DocumentUploadStatus.success, uploaded: uploaded, progress: 1),
      );
    } catch (_) {
      _updateDocument(id, (d) => d.copyWith(status: DocumentUploadStatus.error));
    }
  }

  Future<void> removeDocument(String id) async {
    final doc = state.documents.firstWhere((d) => d.id == id);
    if (doc.uploaded != null) {
      await _repository.deleteDocument(doc.uploaded!.url);
    }
    state = state.copyWith(
      documents: state.documents.where((d) => d.id != id).toList(),
    );
  }

  void _updateDocument(String id, OnboardingDocument Function(OnboardingDocument) update) {
    state = state.copyWith(
      documents: [
        for (final d in state.documents)
          if (d.id == id) update(d) else d,
      ],
    );
  }

  Future<bool> submit() async {
    final uid = _uid;
    if (uid == null || !state.step1Valid || !state.step2Valid || !state.step3Valid) {
      return false;
    }
    state = state.copyWith(isSubmitting: true, clearSubmitError: true);
    try {
      await _repository.finalizeStructure(
        uid: uid,
        nom: state.nom.trim(),
        type: state.structureType!,
        adresse: state.adresse.trim(),
        localisation: GeoPoint(
          state.localisation!.latitude,
          state.localisation!.longitude,
        ),
        documents: state.documents
            .where((d) => d.uploaded != null)
            .map((d) => d.uploaded!)
            .toList(),
        groupesSanguins: state.groupesSanguins.toList(),
        criteresAdditionnels: state.criteresAdditionnels.trim().isEmpty
            ? null
            : state.criteresAdditionnels.trim(),
      );
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, submitError: e.toString());
      return false;
    }
  }
}
