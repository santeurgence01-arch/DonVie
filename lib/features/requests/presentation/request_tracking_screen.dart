import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:health_emergency/core/constants/app_constants.dart';
import 'package:health_emergency/core/providers/current_structure_provider.dart';
import 'package:health_emergency/core/theme/app_theme.dart';
import 'package:health_emergency/core/widgets/blood_type_badge.dart';
import 'package:health_emergency/core/widgets/primary_button.dart';
import 'package:health_emergency/core/widgets/urgency_badge.dart';
import 'package:health_emergency/features/requests/application/requests_providers.dart';
import 'package:health_emergency/features/requests/data/demande_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class RequestTrackingScreen extends ConsumerWidget {
  const RequestTrackingScreen({super.key, required this.demandeId});

  final String demandeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demandeAsync = ref.watch(demandeDetailProvider(demandeId));

    return Scaffold(
      body: demandeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (demande) {
          if (demande == null) {
            return const Center(child: Text('Cette demande est introuvable.'));
          }
          return _TrackingBody(demande: demande);
        },
      ),
    );
  }
}

class _TrackingBody extends ConsumerStatefulWidget {
  const _TrackingBody({required this.demande});

  final DemandeModel demande;

  @override
  ConsumerState<_TrackingBody> createState() => _TrackingBodyState();
}

class _TrackingBodyState extends ConsumerState<_TrackingBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _elargirZone(BuildContext context) async {
    var rayon = widget.demande.rayonKm;
    final structureId = ref.read(currentStructureIdProvider);
    final result = await showModalBottomSheet<double>(
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
                  Text('Élargir la zone de recherche', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Rayon : ${rayon.round()} km', style: Theme.of(context).textTheme.bodyLarge),
                  Slider(
                    value: rayon,
                    min: widget.demande.rayonKm,
                    max: 50,
                    divisions: (50 - widget.demande.rayonKm).round().clamp(1, 200),
                    onChanged: (v) => setSheetState(() => rayon = v),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Relancer avec ce rayon',
                    onPressed: () => Navigator.pop(context, rayon),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == null || structureId == null || !context.mounted) return;
    final newlyNotified = await ref
        .read(demandeRepositoryProvider)
        .elargirEtRelancer(demande: widget.demande, nouveauRayonKm: result);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$newlyNotified nouveau(x) donneur(s) notifié(s).')),
      );
    }
  }

  Future<void> _cloturer(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Le besoin est-il couvert ?'),
        content: const Text('Cette action arrêtera la réception de nouvelles réponses.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clôturer la demande'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(demandeRepositoryProvider).cloturer(widget.demande.id);
    HapticFeedback.mediumImpact();
    if (context.mounted) context.pushReplacement('/requests/history');
  }

  @override
  Widget build(BuildContext context) {
    final demande = widget.demande;
    final reponsesAsync = ref.watch(reponsesProvider(demande.id));
    final reponses = reponsesAsync.value ?? const [];
    final confirmes = reponses.where((r) => r.statut == ReponseStatut.confirme).toList();
    final enAttente = reponses.where((r) => r.statut == ReponseStatut.enAttente).toList();
    final declines = reponses.where((r) => r.statut == ReponseStatut.decline).toList();
    final readOnly = demande.statut == DemandeStatut.cloturee;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                _PulsingUrgencyBadge(level: demande.niveauUrgence),
                const Spacer(),
                if (demande.createdAt != null)
                  Text(
                    'Lancée à ${DateFormat('HH:mm').format(demande.createdAt!)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                children: [
                  for (final bt in demande.groupesSanguins) BloodTypeBadge(label: bt, small: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Confirmés (${confirmes.length})'),
              Tab(text: 'En attente (${enAttente.length})'),
              Tab(text: 'Déclinés (${declines.length})'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ReponsesList(reponses: confirmes, kind: _TabKind.confirme),
                _ReponsesList(reponses: enAttente, kind: _TabKind.enAttente),
                _ReponsesList(reponses: declines, kind: _TabKind.decline),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: readOnly
                ? SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Retour'),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _elargirZone(context),
                          child: const Text('Élargir la zone et relancer'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Clôturer la demande',
                          onPressed: () => _cloturer(context),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

enum _TabKind { confirme, enAttente, decline }

class _ReponsesList extends StatelessWidget {
  const _ReponsesList({required this.reponses, required this.kind});

  final List<ReponseModel> reponses;
  final _TabKind kind;

  Future<void> _call(String telephone) async {
    await launchUrl(Uri(scheme: 'tel', path: telephone));
  }

  @override
  Widget build(BuildContext context) {
    if (reponses.isEmpty) {
      return Center(
        child: Text(
          'Aucun donneur dans cette catégorie pour le moment.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
              .animate(animation),
          child: child,
        ),
      ),
      child: ListView.separated(
        key: ValueKey('${kind}_${reponses.length}'),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: reponses.length,
        separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, index) {
          final r = reponses[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Text(
                r.donneurNom.isNotEmpty ? r.donneurNom[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
            title: Text(r.donneurNom),
            subtitle: Text(
              kind == _TabKind.enAttente && r.notifiedAt != null
                  ? 'notifié ${_relative(r.notifiedAt!)}'
                  : '${r.distanceKm.toStringAsFixed(1)} km',
            ),
            trailing: kind == _TabKind.confirme
                ? IconButton(
                    icon: const Icon(Icons.call_rounded, color: AppColors.secondary),
                    onPressed: () => _call(r.donneurTelephone),
                  )
                : Text('${r.distanceKm.toStringAsFixed(1)} km'),
          );
        },
      ),
    );
  }

  String _relative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    return 'il y a ${diff.inHours} h';
  }
}

class _PulsingUrgencyBadge extends StatefulWidget {
  const _PulsingUrgencyBadge({required this.level});

  final UrgencyLevel level;

  @override
  State<_PulsingUrgencyBadge> createState() => _PulsingUrgencyBadgeState();
}

class _PulsingUrgencyBadgeState extends State<_PulsingUrgencyBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.level == UrgencyLevel.critique) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.level != UrgencyLevel.critique) {
      return UrgencyBadge(level: widget.level, large: true);
    }
    return ScaleTransition(
      scale: Tween<double>(begin: 1, end: 1.08).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: UrgencyBadge(level: widget.level, large: true),
    );
  }
}
