import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:health_emergency/features/donors/data/donor_model.dart';
import 'package:health_emergency/features/stock/data/stock_model.dart';

/// Génère un identifiant donneur de la forme `xxxx-xxxx-xxxx-xxxx`, dans le
/// même esprit que l'exemple du cahier des charges (§4.4.3).
String _generateDonorId() {
  const charset = 'abcdefghijkmnpqrstuvwxyz23456789!\$%?';
  final random = Random.secure();
  String block() => List.generate(
    4,
    (_) => charset[random.nextInt(charset.length)],
  ).join();
  return '${block()}-${block()}-${block()}-${block()}';
}

/// Dérive une adresse e-mail Firebase Auth valide à partir d'un
/// identifiant donneur : l'identifiant contient des symboles (`!$%?`) qui,
/// bien que valides selon la RFC 5322, sont refusés par le validateur
/// d'e-mail (plus strict) de Firebase Auth — on encode donc en
/// hexadécimal plutôt que d'utiliser l'identifiant tel quel. Cette
/// fonction doit rester identique à celle utilisée côté app Donneur
/// (lib/features/auth/data/auth_repository.dart) pour que connexion et
/// création correspondent au même compte.
String donorAuthEmail(String identifiantDon) {
  final hex = identifiantDon.codeUnits
      .map((c) => c.toRadixString(16).padLeft(2, '0'))
      .join();
  return '$hex@donvie.app';
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
  /// collision, extrêmement improbable vu l'espace de génération), ainsi
  /// qu'un compte Firebase Auth associé pour que l'app Donneur puisse s'y
  /// connecter par identifiant.
  ///
  /// Le compte est créé via une instance [FirebaseApp] secondaire pour ne
  /// pas déconnecter l'admin en cours de session (limitation connue du
  /// SDK Firebase Auth : `createUserWithEmailAndPassword` sur l'instance
  /// principale bascule automatiquement la session active vers le
  /// nouveau compte). L'uid du compte créé est utilisé comme id du
  /// document Firestore, afin que les règles de sécurité puissent
  /// simplement comparer `request.auth.uid` à l'id du document donneur —
  /// voir firebase/firestore.rules.
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
    late String identifiantDon;
    for (var attempt = 0; attempt < 5; attempt++) {
      identifiantDon = _generateDonorId();
      final existing = await _collection
          .where('identifiantDon', isEqualTo: identifiantDon)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) break;
    }

    final uid = await _createDonorAuthAccount(identifiantDon);

    final donor = DonorModel(
      id: uid,
      structureId: structureId,
      nom: nom,
      prenom: prenom,
      age: age,
      telephone: telephone,
      groupeSanguin: groupeSanguin,
      identifiantDon: identifiantDon,
      adresse: adresse,
      localisation: localisation,
    );

    await _collection.doc(uid).set(donor.toMap());
    return DonorModel(
      id: uid,
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

  Future<String> _createDonorAuthAccount(String identifiantDon) async {
    final secondaryApp = await Firebase.initializeApp(
      name: 'donorCreation-${DateTime.now().microsecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: donorAuthEmail(identifiantDon),
        password: identifiantDon,
      );
      return credential.user!.uid;
    } finally {
      await secondaryApp.delete();
    }
  }

  Future<void> setActive(String id, bool active) {
    return _collection.doc(id).update({'actif': active});
  }
}
