import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:health_emergency/features/onboarding/data/structure_model.dart';

class StructureRepository {
  StructureRepository(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('structures').doc(uid);

  Stream<StructureModel?> watchStructure(String uid) {
    return _doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return StructureModel.fromMap(data);
    });
  }

  Future<void> finalizeStructure({
    required String uid,
    required String nom,
    required String type,
    required String adresse,
    required GeoPoint localisation,
    required List<StructureDocument> documents,
    required List<String> groupesSanguins,
    String? criteresAdditionnels,
  }) {
    return _doc(uid).set({
      'nom': nom,
      'type': type,
      'adresse': adresse,
      'localisation': localisation,
      'documents': documents.map((d) => d.toMap()).toList(),
      'groupesSanguins': groupesSanguins,
      'criteresAdditionnels': criteresAdditionnels,
      'configurationTerminee': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<StructureDocument> uploadDocument({
    required String uid,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
    void Function(double progress)? onProgress,
  }) async {
    final path =
        'structures/$uid/documents/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final ref = _storage.ref(path);
    final task = ref.putData(bytes, SettableMetadata(contentType: contentType));

    task.snapshotEvents.listen((snapshot) {
      if (snapshot.totalBytes > 0) {
        onProgress?.call(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    });

    final finished = await task;
    final url = await finished.ref.getDownloadURL();
    return StructureDocument(
      nom: fileName,
      url: url,
      taille: bytes.length,
      type: contentType,
    );
  }

  /// Met à jour les champs modifiables du profil structure — §4.9.
  Future<void> updateProfile({
    required String uid,
    String? nom,
    String? adresse,
    GeoPoint? localisation,
    List<StructureDocument>? documents,
  }) {
    final data = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (nom != null) data['nom'] = nom;
    if (adresse != null) data['adresse'] = adresse;
    if (localisation != null) data['localisation'] = localisation;
    if (documents != null) data['documents'] = documents.map((d) => d.toMap()).toList();
    return _doc(uid).set(data, SetOptions(merge: true));
  }

  Future<void> setNotificationPreference({
    required String uid,
    bool? notifStockBas,
    bool? notifResumeActivite,
  }) {
    final data = <String, dynamic>{};
    if (notifStockBas != null) data['notifStockBas'] = notifStockBas;
    if (notifResumeActivite != null) data['notifResumeActivite'] = notifResumeActivite;
    return _doc(uid).set(data, SetOptions(merge: true));
  }

  Future<void> deleteDocument(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {
      // Le fichier a peut-être déjà été supprimé — on ignore.
    }
  }
}
