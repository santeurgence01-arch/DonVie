import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:health_emergency/core/constants/app_constants.dart';
import 'package:health_emergency/core/providers/current_structure_provider.dart';
import 'package:health_emergency/core/theme/app_theme.dart';
import 'package:health_emergency/core/widgets/app_text_field.dart';
import 'package:health_emergency/core/widgets/primary_button.dart';
import 'package:health_emergency/features/auth/application/auth_providers.dart';
import 'package:health_emergency/features/donors/presentation/widgets/location_picker_dialog.dart';
import 'package:health_emergency/features/onboarding/application/onboarding_providers.dart';
import 'package:health_emergency/features/onboarding/data/structure_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nomController = TextEditingController();
  final _adresseController = TextEditingController();
  GeoPoint? _localisation;
  List<StructureDocument> _documents = const [];
  bool _initialized = false;
  bool _dirty = false;
  bool _isSaving = false;
  bool _isUploadingDoc = false;

  void _initFrom(StructureModel structure) {
    if (_initialized) return;
    _initialized = true;
    _nomController.text = structure.nom ?? '';
    _adresseController.text = structure.adresse ?? '';
    _localisation = structure.localisation;
    _documents = List.of(structure.documents);
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    _nomController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final structureLocation = ref.read(structureDocProvider).value?.localisation;
    final initial = _localisation != null
        ? LatLng(_localisation!.latitude, _localisation!.longitude)
        : (structureLocation != null
              ? LatLng(structureLocation.latitude, structureLocation.longitude)
              : const LatLng(4.0511, 9.7679));
    final picked = await showLocationPickerDialog(context, initialPosition: initial);
    if (picked == null) return;
    setState(() {
      _localisation = GeoPoint(picked.latitude, picked.longitude);
    });
    _markDirty();
  }

  Future<void> _addDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    final uid = ref.read(currentStructureIdProvider);
    if (uid == null) return;

    setState(() => _isUploadingDoc = true);
    try {
      final uploaded = await ref
          .read(structureRepositoryProvider)
          .uploadDocument(
            uid: uid,
            fileName: file.name,
            bytes: file.bytes!,
            contentType: 'application/octet-stream',
          );
      setState(() {
        _documents = [..._documents, uploaded];
        _isUploadingDoc = false;
      });
      _markDirty();
    } catch (_) {
      if (mounted) setState(() => _isUploadingDoc = false);
    }
  }

  Future<void> _removeDocument(StructureDocument doc) async {
    final uid = ref.read(currentStructureIdProvider);
    if (uid == null) return;
    await ref.read(structureRepositoryProvider).deleteDocument(doc.url);
    setState(() {
      _documents = _documents.where((d) => d.url != doc.url).toList();
    });
    _markDirty();
  }

  Future<void> _saveChanges() async {
    final uid = ref.read(currentStructureIdProvider);
    if (uid == null) return;
    setState(() => _isSaving = true);
    await ref
        .read(structureRepositoryProvider)
        .updateProfile(
          uid: uid,
          nom: _nomController.text.trim(),
          adresse: _adresseController.text.trim(),
          localisation: _localisation,
          documents: _documents,
        );
    if (mounted) {
      setState(() {
        _isSaving = false;
        _dirty = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modifications enregistrées')),
      );
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authRepositoryProvider).signOut();
    }
  }

  Future<void> _openChangePassword() async {
    await showDialog<void>(
      context: context,
      builder: (context) => const _ChangePasswordDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < kMobileBreakpoint;
    final structureAsync = ref.watch(structureDocProvider);
    final email = ref.watch(authStateProvider).value?.email ?? '—';

    return structureAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur : $e')),
      data: (structure) {
        if (structure != null) _initFrom(structure);

        return SafeArea(
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? AppSpacing.screenPaddingMobile : AppSpacing.screenPaddingWeb,
              vertical: AppSpacing.sectionGap,
            ),
            children: [
              Text('Profil', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sectionGap),
              Text('Informations de la structure', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Nom de la structure',
                controller: _nomController,
                onChanged: (_) => _markDirty(),
              ),
              const SizedBox(height: AppSpacing.fieldGap),
              AppTextField(
                label: 'Adresse',
                controller: _adresseController,
                prefixIcon: Icons.place_outlined,
                onChanged: (_) => _markDirty(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map_outlined),
                  tooltip: 'Repositionner sur la carte',
                  onPressed: _pickLocation,
                ),
              ),
              const SizedBox(height: AppSpacing.fieldGap),
              Text('Documents légaux', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              for (final doc in _documents)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description_outlined, color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(doc.nom, overflow: TextOverflow.ellipsis),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => _removeDocument(doc),
                      ),
                    ],
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _isUploadingDoc ? null : _addDocument,
                icon: _isUploadingDoc
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file_outlined),
                label: const Text('Ajouter un document'),
              ),
              if (_dirty) ...[
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Enregistrer les modifications',
                  isLoading: _isSaving,
                  onPressed: _saveChanges,
                ),
              ],
              const SizedBox(height: AppSpacing.sectionGap),
              const Divider(),
              const SizedBox(height: AppSpacing.sectionGap),
              Text('Compte administrateur', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.mail_outline),
                title: Text(email),
                subtitle: const Text('Adresse e-mail de connexion'),
              ),
              OutlinedButton(
                onPressed: _openChangePassword,
                child: const Text('Changer le mot de passe'),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              const Divider(),
              const SizedBox(height: AppSpacing.sectionGap),
              Text('Notifications', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Alertes de stock bas'),
                value: structure?.notifStockBas ?? true,
                onChanged: (v) {
                  final uid = ref.read(currentStructureIdProvider);
                  if (uid != null) {
                    ref
                        .read(structureRepositoryProvider)
                        .setNotificationPreference(uid: uid, notifStockBas: v);
                  }
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Résumés d'activité par e-mail"),
                value: structure?.notifResumeActivite ?? true,
                onChanged: (v) {
                  final uid = ref.read(currentStructureIdProvider);
                  if (uid != null) {
                    ref
                        .read(structureRepositoryProvider)
                        .setNotificationPreference(uid: uid, notifResumeActivite: v);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Center(
                child: TextButton(
                  onPressed: _confirmLogout,
                  style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                  child: const Text('Déconnexion'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).changePassword(
            currentPassword: _oldController.text,
            newPassword: _newController.text,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mot de passe modifié')),
        );
      }
    } catch (_) {
      setState(() {
        _isSubmitting = false;
        _error = 'Mot de passe actuel incorrect ou erreur réseau.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Changer le mot de passe'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: 'Mot de passe actuel',
              controller: _oldController,
              isPassword: true,
              validator: (v) => (v == null || v.isEmpty) ? 'Requis.' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Nouveau mot de passe',
              controller: _newController,
              isPassword: true,
              validator: (v) =>
                  (v == null || v.length < 6) ? '6 caractères minimum.' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Confirmer le nouveau mot de passe',
              controller: _confirmController,
              isPassword: true,
              validator: (v) => v != _newController.text ? 'Les mots de passe diffèrent.' : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ],
          ],
        ),
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
