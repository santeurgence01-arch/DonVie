import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_emergency/core/constants/app_constants.dart';

/// Doc `demandes/{id}` — §4.6 / §4.7 / §4.8.
class DemandeModel {
  const DemandeModel({
    required this.id,
    required this.structureId,
    required this.groupesSanguins,
    required this.niveauUrgence,
    required this.rayonKm,
    required this.statut,
    required this.nombreDonneursEstime,
    this.localisation,
    this.createdAt,
    this.closedAt,
  });

  final String id;
  final String structureId;
  final List<String> groupesSanguins;
  final UrgencyLevel niveauUrgence;
  final double rayonKm;
  final DemandeStatut statut;
  final int nombreDonneursEstime;
  final GeoPoint? localisation;
  final DateTime? createdAt;
  final DateTime? closedAt;

  factory DemandeModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return DemandeModel(
      id: doc.id,
      structureId: data['structureId'] as String? ?? '',
      groupesSanguins: List<String>.from(
        data['groupesSanguins'] as List<dynamic>? ?? const [],
      ),
      niveauUrgence: UrgencyLevel.fromValue(
        data['niveauUrgence'] as String? ?? 'normal',
      ),
      rayonKm: (data['rayonKm'] as num?)?.toDouble() ?? 5,
      statut: (data['statut'] as String?) == 'cloturee'
          ? DemandeStatut.cloturee
          : DemandeStatut.active,
      nombreDonneursEstime: (data['nombreDonneursEstime'] as num?)?.toInt() ?? 0,
      localisation: data['localisation'] as GeoPoint?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      closedAt: (data['closedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'structureId': structureId,
      'groupesSanguins': groupesSanguins,
      'niveauUrgence': niveauUrgence.value,
      'rayonKm': rayonKm,
      'statut': 'active',
      'nombreDonneursEstime': nombreDonneursEstime,
      'localisation': localisation,
      'createdAt': FieldValue.serverTimestamp(),
      'closedAt': null,
    };
  }
}

/// Doc `reponses/{id}` — réponse (ou notification en attente) d'un donneur
/// à une demande. Les champs donneur sont dénormalisés pour permettre un
/// affichage temps réel sans requête supplémentaire — §4.7.
class ReponseModel {
  const ReponseModel({
    required this.id,
    required this.demandeId,
    required this.structureId,
    required this.donneurId,
    required this.donneurNom,
    required this.donneurTelephone,
    required this.donneurGroupeSanguin,
    required this.distanceKm,
    required this.statut,
    this.notifiedAt,
    this.respondedAt,
  });

  final String id;
  final String demandeId;
  final String structureId;
  final String donneurId;
  final String donneurNom;
  final String donneurTelephone;
  final String donneurGroupeSanguin;
  final double distanceKm;
  final ReponseStatut statut;
  final DateTime? notifiedAt;
  final DateTime? respondedAt;

  factory ReponseModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final statutStr = data['statut'] as String? ?? 'en_attente';
    return ReponseModel(
      id: doc.id,
      demandeId: data['demandeId'] as String? ?? '',
      structureId: data['structureId'] as String? ?? '',
      donneurId: data['donneurId'] as String? ?? '',
      donneurNom: data['donneurNom'] as String? ?? '',
      donneurTelephone: data['donneurTelephone'] as String? ?? '',
      donneurGroupeSanguin: data['donneurGroupeSanguin'] as String? ?? '',
      distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0,
      statut: switch (statutStr) {
        'confirme' => ReponseStatut.confirme,
        'decline' => ReponseStatut.decline,
        _ => ReponseStatut.enAttente,
      },
      notifiedAt: (data['notifiedAt'] as Timestamp?)?.toDate(),
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
    );
  }
}
