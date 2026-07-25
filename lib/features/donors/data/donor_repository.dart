import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health_emergency/features/donors/data/donor_model.dart';
import 'package:health_emergency/features/stock/data/stock_model.dart';

/// Génère un identifiant donneur de la forme `xxxx-xxxx-xxxx-xxxx`, dans le
/// même esprit que l'exemple du cahier des charges (§4.4.3).
///
/// Dans une architecture complète, cet identifiant serait généré côté
/// serveur par la Cloud Function `genererIdDonneur` (pour garantir
/// l'unicité de façon atomique et déclencher l'appel Twilio le cas
/// échéant) — ici, en l'absence de backend Cloud Functions dans ce
/// dépôt, la génération se fait côté client puis est vérifiée pour
/// collision avant écriture.
String _generateDonorId() {
  const charset = 'abcdefghijkmnpqrstuvwxyz23456789!\$%?';
  final random = Random.secure();
  String block() => List.generate(
    4,
    (_) => charset[random.nextInt(charset.length)],
  ).join();
  return '${block()}-${block()}-${block()}-${block()}';
}

class DonorRepository {
  DonorRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('donneurs');

  CollectionReference<Map<String, dynamic>> get _mouvements =>
      _firestore.collection('historique_dons');

  Stream<List<DonorModel>> watchDonors(String structureId) {
    return _collection
        .where('structureId', isEqualTo: structureId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(DonorModel.fromDoc).toList());
  }

  Stream<DonorModel?> watchDonor(String id) {
    return _collection.doc(id).snapshots().map(
      (doc) => doc.exists ? DonorModel.fromDoc(doc) : null,
    );
  }

  Stream<List<MouvementStock>> watchDonorHistory(String donorId) {
    return _mouvements
        .where('donneurId', isEqualTo: donorId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(MouvementStock.fromDoc).toList());
  }

  /// Crée le donneur avec un identifiant unique (retente en cas de
  /// collision, extrêmement improbable vu l'espace de génération).
  Future<DonorModel> createDonor({
    required String structureId,
    required String nom,
    required String prenom,
    required int age,
    required String telephone,
    required String groupeSanguin,
    required GeoPoint? localisation,
    String? adresse,
  }) async {
    late String id;
    for (var attempt = 0; attempt < 5; attempt++) {
      id = _generateDonorId();
      final existing = await _collection
          .where('identifiantDon', isEqualTo: id)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) break;
    }

    final donor = DonorModel(
      id: '',
      structureId: structureId,
      nom: nom,
      prenom: prenom,
      age: age,
      telephone: telephone,
      groupeSanguin: groupeSanguin,
      identifiantDon: id,
      adresse: adresse,
      localisation: localisation,
    );

    final ref = await _collection.add(donor.toMap());
    return DonorModel(
      id: ref.id,
      structureId: donor.structureId,
      nom: donor.nom,
      prenom: donor.prenom,
      age: donor.age,
      telephone: donor.telephone,
      groupeSanguin: donor.groupeSanguin,
      identifiantDon: donor.identifiantDon,
      adresse: donor.adresse,
      localisation: donor.localisation,
      createdAt: DateTime.now(),
    );
  }

  Future<void> setActive(String id, bool active) {
    return _collection.doc(id).update({'actif': active});
  }
}
