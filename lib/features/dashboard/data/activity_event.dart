import 'package:flutter/material.dart';

enum ActivityType { nouvelleDemande, reponseDonneur, nouveauDonneur, mouvementStock }

/// Événement composite affiché dans "Activité récente" — §4.3, point 5.
/// Fusionné côté client à partir de 4 flux Firestore distincts (demandes,
/// réponses, donneurs, historique_dons) faute de collection d'événements
/// dédiée dans le modèle de données.
class ActivityEvent {
  const ActivityEvent({
    required this.type,
    required this.description,
    required this.timestamp,
  });

  final ActivityType type;
  final String description;
  final DateTime timestamp;

  IconData get icon => switch (type) {
    ActivityType.nouvelleDemande => Icons.campaign_outlined,
    ActivityType.reponseDonneur => Icons.how_to_reg_outlined,
    ActivityType.nouveauDonneur => Icons.person_add_alt_outlined,
    ActivityType.mouvementStock => Icons.swap_vert_rounded,
  };
}

/// Formatage relatif façon "il y a 5 min" / "hier à 14h30" — §4.3.
String formatRelativeTime(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inMinutes < 1) return "à l'instant";
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24 && now.day == date.day) {
    return 'il y a ${diff.inHours} h';
  }
  final yesterday = now.subtract(const Duration(days: 1));
  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  if (date.year == yesterday.year &&
      date.month == yesterday.month &&
      date.day == yesterday.day) {
    return 'hier à ${hh}h$mm';
  }
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')} à ${hh}h$mm';
}
