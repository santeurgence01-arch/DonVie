import 'package:cloud_firestore/cloud_firestore.dart';

class DonorModel {
  const DonorModel({
    required this.id,
    required this.structureId,
    required this.nom,
    required this.prenom,
    required this.age,
    required this.telephone,
    required this.groupeSanguin,
    required this.identifiantDon,
    this.adresse,
    this.localisation,
    this.actif = true,
    this.createdAt,
  });

  final String id;
  final String structureId;
  final String nom;
  final String prenom;
  final int age;
  final String telephone;
  final String groupeSanguin;
  final String identifiantDon;
  final String? adresse;
  final GeoPoint? localisation;
  final bool actif;
  final DateTime? createdAt;

  String get nomComplet => '$prenom $nom';

  String get initiales {
    final p = prenom.isNotEmpty ? prenom[0] : '';
    final n = nom.isNotEmpty ? nom[0] : '';
    return ('$p$n').toUpperCase();
  }

  factory DonorModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return DonorModel(
      id: doc.id,
      structureId: data['structureId'] as String? ?? '',
      nom: data['nom'] as String? ?? '',
      prenom: data['prenom'] as String? ?? '',
      age: (data['age'] as num?)?.toInt() ?? 0,
      telephone: data['telephone'] as String? ?? '',
      groupeSanguin: data['groupeSanguin'] as String? ?? '',
      identifiantDon: data['identifiantDon'] as String? ?? '',
      adresse: data['adresse'] as String?,
      localisation: data['localisation'] as GeoPoint?,
      actif: data['actif'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'structureId': structureId,
      'nom': nom,
      'prenom': prenom,
      'age': age,
      'telephone': telephone,
      'groupeSanguin': groupeSanguin,
      'identifiantDon': identifiantDon,
      'adresse': adresse,
      'localisation': localisation,
      'actif': actif,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
