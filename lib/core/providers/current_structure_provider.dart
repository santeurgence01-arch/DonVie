import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_emergency/features/auth/application/auth_providers.dart';

/// Une structure = un compte admin : l'UID Firebase Auth sert directement
/// d'identifiant `structureId` dans toutes les collections.
final currentStructureIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.uid;
});
