import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:health_emergency/core/constants/app_constants.dart';
import 'package:health_emergency/features/donors/data/donor_model.dart';
import 'package:health_emergency/features/requests/data/demande_model.dart';

class DemandeRepository {
  DemandeRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _demandes =>
      _firestore.collection('demandes');

  CollectionReference<Map<String, dynamic>> get _reponses =>
      _firestore.collection('reponses');

  CollectionReference<Map<String, dynamic>> get _donneurs =>
      _firestore.collection('donneurs');

  double _distanceKm(GeoPoint a, GeoPoint b) {
    return Geolocator.distanceBetween(
          a.latitude,
          a.longitude,
          b.latitude,
          b.longitude,
        ) /
        1000;
  }

  /// Donneurs actifs de la structure dont le groupe sanguin correspond,
  /// sans encore filtrer par zone — utilisé pour l'aperçu de l'étape 1.
  Future<List<DonorModel>> matchingDonors({
    required String structureId,
    required List<String> groupesSanguins,
  }) async {
    if (groupesSanguins.isEmpty) return [];
    final snap = await _donneurs
        .where('structureId', isEqualTo: structureId)
        .where('actif', isEqualTo: true)
        .where('groupeSanguin', whereIn: groupesSanguins)
        .get();
    return snap.docs.map(DonorModel.fromDoc).toList();
  }

  /// Filtre en plus par rayon (calcul client, adapté au volume d'une
  /// structure) — utilisé pour l'aperçu de l'étape 3.
  Future<List<DonorModel>> matchingDonorsInRadius({
    required String structureId,
    required List<String> groupesSanguins,
    required GeoPoint centre,
    required double rayonKm,
  }) async {
    final donors = await matchingDonors(
      structureId: structureId,
      groupesSanguins: groupesSanguins,
    );
    return donors
        .where(
          (d) => d.localisation != null &&
              _distanceKm(centre, d.localisation!) <= rayonKm,
        )
        .toList();
  }

  Stream<List<DemandeModel>> watchActive(String structureId) {
    return _demandes
        .where('structureId', isEqualTo: structureId)
        .where('statut', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(DemandeModel.fromDoc).toList());
  }

  Stream<List<DemandeModel>> watchHistory(String structureId) {
    return _demandes
        .where('structureId', isEqualTo: structureId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map(DemandeModel.fromDoc).toList());
  }

  Stream<DemandeModel?> watchDemande(String id) {
    return _demandes.doc(id).snapshots().map(
      (doc) => doc.exists ? DemandeModel.fromDoc(doc) : null,
    );
  }

  Stream<List<ReponseModel>> watchReponses(String demandeId) {
    return _reponses
        .where('demandeId', isEqualTo: demandeId)
        .snapshots()
        .map((snap) => snap.docs.map(ReponseModel.fromDoc).toList());
  }

  /// Réponses les plus récentes tous groupes/demandes confondus, pour le
  /// flux "Activité récente" du Dashboard — §4.3.
  Stream<List<ReponseModel>> watchRecentReponses(String structureId) {
    return _reponses
        .where('structureId', isEqualTo: structureId)
        .where('statut', whereIn: ['confirme', 'decline'])
        .orderBy('respondedAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snap) => snap.docs.map(ReponseModel.fromDoc).toList());
  }

  /// Diffuse une nouvelle demande : crée le document `demandes/{id}` puis
  /// une entrée `reponses` (statut "en_attente") pour chaque donneur
  /// compatible dans le rayon — la notification push / l'appel Twilio pour
  /// les demandes Critiques relèvent d'une Cloud Function déclenchée par
  /// la création de ces documents, hors périmètre du code client Flutter.
  Future<DemandeModel> creerEtDiffuser({
    required String structureId,
    required List<String> groupesSanguins,
    required UrgencyLevel niveauUrgence,
    required double rayonKm,
    required GeoPoint centre,
  }) async {
    final donors = await matchingDonorsInRadius(
      structureId: structureId,
      groupesSanguins: groupesSanguins,
      centre: centre,
      rayonKm: rayonKm,
    );

    final demandeRef = _demandes.doc();
    final demande = DemandeModel(
      id: demandeRef.id,
      structureId: structureId,
      groupesSanguins: groupesSanguins,
      niveauUrgence: niveauUrgence,
      rayonKm: rayonKm,
      statut: DemandeStatut.active,
      nombreDonneursEstime: donors.length,
      localisation: centre,
      createdAt: DateTime.now(),
    );

    final batch = _firestore.batch();
    batch.set(demandeRef, demande.toCreateMap());
    for (final donor in donors) {
      final reponseRef = _reponses.doc();
      batch.set(reponseRef, {
        'demandeId': demandeRef.id,
        'structureId': structureId,
        'donneurId': donor.id,
        'donneurNom': donor.nomComplet,
        'donneurTelephone': donor.telephone,
        'donneurGroupeSanguin': donor.groupeSanguin,
        'distanceKm': donor.localisation != null
            ? _distanceKm(centre, donor.localisation!)
            : 0,
        'statut': 'en_attente',
        'notifiedAt': FieldValue.serverTimestamp(),
        'respondedAt': null,
      });
    }
    await batch.commit();
    return demande;
  }

  /// Élargit le rayon et notifie les nouveaux donneurs compatibles non
  /// déjà notifiés — §4.7 "Élargir la zone et relancer".
  Future<int> elargirEtRelancer({
    required DemandeModel demande,
    required double nouveauRayonKm,
  }) async {
    if (demande.localisation == null) return 0;
    final donors = await matchingDonorsInRadius(
      structureId: demande.structureId,
      groupesSanguins: demande.groupesSanguins,
      centre: demande.localisation!,
      rayonKm: nouveauRayonKm,
    );

    final existing = await _reponses
        .where('demandeId', isEqualTo: demande.id)
        .get();
    final alreadyNotified = existing.docs
        .map((d) => d.data()['donneurId'] as String)
        .toSet();

    final newDonors = donors
        .where((d) => !alreadyNotified.contains(d.id))
        .toList();

    final batch = _firestore.batch();
    batch.update(_demandes.doc(demande.id), {
      'rayonKm': nouveauRayonKm,
      'nombreDonneursEstime': demande.nombreDonneursEstime + newDonors.length,
    });
    for (final donor in newDonors) {
      final reponseRef = _reponses.doc();
      batch.set(reponseRef, {
        'demandeId': demande.id,
        'structureId': demande.structureId,
        'donneurId': donor.id,
        'donneurNom': donor.nomComplet,
        'donneurTelephone': donor.telephone,
        'donneurGroupeSanguin': donor.groupeSanguin,
        'distanceKm': donor.localisation != null
            ? _distanceKm(demande.localisation!, donor.localisation!)
            : 0,
        'statut': 'en_attente',
        'notifiedAt': FieldValue.serverTimestamp(),
        'respondedAt': null,
      });
    }
    await batch.commit();
    return newDonors.length;
  }

  Future<void> cloturer(String demandeId) {
    return _demandes.doc(demandeId).update({
      'statut': 'cloturee',
      'closedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Simule la réponse d'un donneur (confirmé/décliné) — dans l'app réelle
  /// ce champ est mis à jour par l'application donneur elle-même ; exposé
  /// ici pour permettre à l'admin de saisir une réponse reçue par un autre
  /// canal (téléphone).
  Future<void> marquerReponse(String reponseId, ReponseStatut statut) {
    return _reponses.doc(reponseId).update({
      'statut': switch (statut) {
        ReponseStatut.confirme => 'confirme',
        ReponseStatut.decline => 'decline',
        ReponseStatut.enAttente => 'en_attente',
      },
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }
}
